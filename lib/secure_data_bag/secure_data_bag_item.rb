
require 'open-uri'
require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'chef/encrypted_data_bag_item/encryptor'
require 'chef/encrypted_data_bag_item/decryptor'

module SecureDataBag
  #
  # SecureDataBagItem extends the standard DataBagItem by providing it
  # with encryption / decryption capabilities.
  #
  # Although it does provide methods which may be used to specifically perform
  # crypto functions, it should be used the same way.
  #

  class Item < Chef::DataBagItem
    def initialize(opts={})
      # Chef 12.3 introduced the new option
      begin super(chef_server_rest: opts.delete(:chef_server_rest))
      rescue ArgumentError; super()
      end

      secret_path     opts[:secret_path] if opts[:secret_path]
      secret          opts[:secret] if opts[:secret]
      encoded_fields  opts[:fields] if opts[:fields]

      self.raw_data = opts[:data] if opts[:data]
      self
    end

    #
    # Path to encryption key file
    #
    def secret_path(arg=nil)
      set_or_return :secret_path, arg, 
        kind_of: String,
        default: self.class.secret_path
    end

    def self.secret_path(arg=nil)
      arg || 
      Chef::Config[:knife][:secure_data_bag][:secret_file] ||
      Chef::Config[:encrypted_data_bag_secret]
    end

    #
    # Content of encryption secret
    #
    def secret(arg=nil)
      @secret = arg unless arg.nil?
      @secret ||= load_secret
    end

    def load_secret
      @secret = self.class.load_secret(secret_path)
    end

    def self.load_secret(path=nil)
      Chef::EncryptedDataBagItem.load_secret(secret_path(path))
    end

    #
    # Fetch databag item via DataBagItem and then optionally decrypt
    #
    def self.load(data_bag, name, opts={})
      data = super(data_bag, name)
      new(opts.merge(data:data.to_hash))
    end

    #
    # Setter for @raw_data
    # - ensure the data we receive is a Mash to support symbols
    # - pass it to DataBagItem for additional validation
    # - ensure the data has the encryption hash
    # - decode the data
    #
    def raw_data=(data)
      data = Mash.new(data)
      super(data)
      decode_data!
    end

    #
    # Fields we wish to encode
    #
    def encoded_fields(arg=nil)
      @encoded_fields = Array(arg).map{|s|s.to_s}.uniq if arg
      @encoded_fields ||= Chef::Config[:knife][:secure_data_bag][:fields] ||
                          Array.new
    end

    #
    # Raw Data decoder methods
    #
    def decode_data!
      @raw_data = decoded_data
      @raw_data
    end

    def decoded_data
      if encoded_value?(@raw_data) then decode_value(@raw_data)
      else decode_hash(@raw_data)
      end
    end

    def decode_hash(hash)
      hash.each do |k,v|
        v = if encoded_value?(v)
              encoded_fields encoded_fields << k
              decode_value(v)
            elsif v.is_a?(Hash)
              decode_hash(v)
            else v
            end
        hash[k] = v
      end
      hash
    end

    def decode_value(value)
      Chef::EncryptedDataBagItem::Decryptor.
        for(value, secret).for_decrypted_item
    end

    def encoded_value?(value)
      value.is_a?(Hash) and value.key?(:encrypted_data)
    end

    #
    # Raw Data encoded methods
    #
    def encode_data!
      @raw_data = encoded_data
      @raw_data
    end

    def encoded_data
      encode_hash(@raw_data.dup)
    end

    def encode_hash(hash)
      hash.each do |k,v|
        v = if encoded_fields.include?(k) then encode_value(v)
            elsif v.is_a?(Hash) then encode_hash(v)
            else v
            end
        hash[k] = v
      end
      hash
    end

    def encode_value(value)
      Chef::EncryptedDataBagItem::Encryptor.
        new(value, secret).for_encrypted_item
    end

    #
    # Transitions
    #
    def self.from_hash(h, opts={})
      item = new(opts.merge(data:h))
      item
    end

    def self.from_item(h, opts={})
      item = self.from_hash(h.to_hash, opts)
      item.data_bag h.data_bag
      item.encoded_fields h.encoded_fields if h.respond_to?(:encoded_fields)
      item
    end

    def to_hash(opts={})
      result = opts[:encoded] ? encoded_data : @raw_data
      result["chef_type"] = "data_bag_item"
      result["data_bag"] = data_bag
      result
    end

    def to_json(*a)
      result = {
        name: self.object_name,
        json_class: "Chef::DataBagItem",
        chef_type: "data_bag_item",
        data_bag: data_bag,
        raw_data: encoded_data
      }
      result.to_json(*a)
    end
  end
end

