require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'secure_data_bag/constants'
require 'secure_data_bag/decryptor'
require 'secure_data_bag/encryptor'

module SecureDataBag
  class Item < Chef::DataBagItem
    class << self
      # Class method used to load the secret key from path
      # @param path [String] the optional path to the file
      # @return [String] the secret
      # @since 3.0.0
      def load_secret(path = nil)
        path ||= (
          Chef::Config[:knife][:secure_data_bag][:secret_file] ||
          Chef::Config[:encrypted_data_bag_secret]
        )
        Chef::EncryptedDataBagItem.load_secret(path)
      end

      # Load a data_bag_item and convert into the a SecureDataBag::Item.
      # @param data_bag [String] the data_bag to load the item from
      # @param name [String] the data_bag_item id
      # @param opts [Hash] optional options to pass to SecureDataBag::Item.new
      # @return [SecureDataBag::Item]
      # @since 3.0.0
      def load(data_bag, name, opts = {})
        data = {
          'data_bag' => data_bag,
          'id' => name
        }.merge(
          Chef::DataBagItem.load(data_bag, name).to_hash
        )
        item = from_hash(data, opts)
        item
      end

      # Create a new SecureDataBag::Item from a hash and optional options.
      # @param hash [Hash] the data
      # @param opts [Hash] the optional options to pass to Item.new
      # @return [SecureDataBag::Item]
      # @since 3.0.0
      def from_hash(hash, opts = {})
        data = hash.dup
        data.delete('chef_type')
        data.delete('json_class')

        metadata = Mash.new(data.delete(SecureDataBag::METADATA_KEY) || {})
        metadata = metadata.merge(opts)

        item = new(metadata)
        item.data_bag(data.delete('data_bag')) if data.key?('data_bag')
        item.raw_data = data.key?('raw_data') ? data['raw_data'] : data
        item
      end

      # Create a new SecureDataBag::Item from a DataBagItem.
      # @param data_bag_item [Chef::DataBagItem] the item to create from
      # @param opts [Hash] the optional options ot pass to Item.new
      # @return [SecureDataBag::Item]
      # @since 3.0.0
      def from_item(data_bag_item, opts = {})
        data = data_bag_item.to_hash
        from_hash(data, opts)
      end
    end

    # Initializer
    # @param opts [Hash] optional options to configure the SecureDataBag::Item
    #        opts[:data] the initial data to set
    #        opts[:secret] the secret key to use when encrypting/decrypting
    #        opts[:secret_path] the path to the secret key
    #        opts[:encrypted_keys] an array of keys to encrypt
    #        opts[:format] the SecureDataBag::Item format to enforce
    # @since 3.0.0
    def initialize(opts = {})
      opts = Mash.new(opts)

      # Initiate the APIClient in Chef 12.3+
      begin super(chef_server_rest: opts.delete(:chef_server_rest))
      rescue ArgumentError; super()
      end

      # Optionally define the Item vesion
      @version = opts[:version] || SecureDataBag::VERSION

      # Optionally define the Item formats
      @encryption_format = opts[:encryption_format]
      @decryption_format = opts[:decryption_format]

      # Optionally provide the shared secret
      @secret = opts[:secret] if opts[:secret]

      # Optionally provide a path to the shared secret. If not provided, the
      # secret loader will automatically attempt to select one.
      @secret_path = opts[:secret_path]

      # Optionally provide a list of keys that should be encrypted or attempt
      # to determine it based on configuration options.
      @encrypted_keys = (
        opts[:encrypted_keys] ||
        Chef::Config[:knife][:secure_data_bag][:encrypted_keys] ||
        []
      ).uniq

      self.raw_data = opts[:data] if opts[:data]
      self
    end

    # Array of hash keys which should be encrypted when encrypting this item.
    # For previously decrypted items, this will contain the keys which has
    # previously been encrypted.
    # @since 3.0.0
    attr_accessor :encrypted_keys

    # Format to enforce when encrypting this Item. This item will automatically
    # be updated when importing encrypted data.
    # @since 3.0.0
    attr_accessor :encryption_format

    # Format to enforce when decrypting this Item. This item will automatically
    # be updated when importing decrypted data.
    # @since 3.0.0
    attr_accessor :decryption_format

    # Fetch, Set or optionally Load the shared secret
    # @param arg [String] optionally set the shared set
    # @return [String] the shared secret
    # @since 3.0.0
    def secret(arg = nil)
      @secret = arg unless arg.nil?
      @secret ||= load_secret
    end

    # Hash representing the metadata associated to this Item
    # @return [Hash] the metadata
    # @since 3.0.0
    def metadata
      Mash.new(
        encryption_format: @encryption_format,
        decryption_format: @decryption_format,
        encrypted_keys: @encrypted_keys,
        version: @version
      )
    end

    # Override the default setter to first ensure that the data is a Mash and
    # then to automatically decrypt the data.
    # @param new_data [Hash] the potentially encrypted data
    # @since 3.0.0
    def raw_data=(new_data)
      new_data = Mash.new(new_data)
      new_data.delete(SecureDataBag::METADATA_KEY)
      super(decrypt_data!(new_data))
    end

    # Export this SecureDataBag::Item to it's raw_data
    # @param opts [Hash] the optional options
    # @return [Hash]
    # @since 3.0.0
    def to_data(opts = {})
      opts = Mash.new(opts)
      result = opts[:encrypt] ? encrypt_data(raw_data) : raw_data
      result[SecureDataBag::METADATA_KEY] = metadata if opts[:metadata]
      result
    end

    # Export this SecureDataBag::Item to a Chef::DataBagItem compatible hash
    # @param opts [Hash] the optional options
    # @return [Hash]
    # @since 3.0.0
    def to_hash(opts = {})
      opts = Mash.new(opts)
      result = to_data(opts)
      result['chef_type'] = 'data_bag_item'
      result['data_bag'] = data_bag.to_s
      result
    end

    # Export this SecureDataBag::Item to a Chef::DataBagItem compatible json
    # @return [String]
    # @since 3.0.0
    def to_json(*a)
      result = {
        'name' => object_name,
        'json_class' => 'Chef::DataBagItem',
        'chef_type' => 'data_bag_item',
        'data_bag' => data_bag.to_s,
        'raw_data' => encrypt_data(raw_data)
      }
      result.to_json(*a)
    end

    private

    # Load the shared secret from the configured secret_path (or auto-detect
    # the path if undefined).
    # @return [String] the shared secret
    # @since 3.0.0
    def load_secret
      @secret = self.class.load_secret(@secret_path)
    end

    # Decrypt the data, save the both the decrypted_keys and format for
    # possible re-encryption, and return the descrypted hash.
    # @param data [Hash] the potentially encrypted hash
    # @param save [Boolean] whether to save the encrypted keys and format
    # @return [Hash] the decrypted hash
    # @since 3.0.0
    def decrypt_data(data, save: false)
      decryptor = SecureDataBag::Decryptor.for(data, secret, metadata)
      decryptor.decrypt!
      @encrypted_keys.concat(decryptor.decrypted_keys).uniq! if save
      @decryption_format = decryptor.format if save
      decryptor.decrypted_hash
    end

    def decrypt_data!(data)
      decrypt_data(data, save: true)
    end

    # Encrypt the data and save the encrypted_keys.
    # @param data [Hash] the hash to encrypt
    # @param save [Boolean] whether to save the encrypted keys
    # @return [Hash] the encrypted hash
    # @since 3.0.0
    def encrypt_data(data, _save: false)
      encryptor = SecureDataBag::Encryptor.new(data, secret, metadata)
      encryptor.encrypt!
      encrypted_hash = encryptor.encrypted_hash
      # Ensure that protected fields are never encrypted
      encrypted_hash['data_bag'] = raw_data['data_bag']
      encrypted_hash['id'] = raw_data['id']
      encrypted_hash
    end

    def encrypt_data!(data)
      encrypt_data(data, save: true)
    end
  end
end

SecureDataBagItem = SecureDataBag::Item
