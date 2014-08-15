
require 'open-uri'
require 'chef/data_bag_item'

module SecureDataBag
  #
  # SecureDataBagItem extends the standard DataBagItem by providing it
  # with encryption / decryption capabilities.
  #
  # Although it does provide methods which may be used to specifically perform
  # crypto functions, it should be used the same way.
  #

  class Item < Chef::DataBagItem
    def initialize(key=nil)
      super()

      @secret = Chef::Config[:encrypted_data_bag_secret]
      @key = key
      @raw_data = {}
      @encode_fields = ["password"]
    end

    #
    # Methods for encryption key
    #

    def secret(arg=nil)
      set_or_return(:secret, arg, kind_of: String)
    end

    def key(arg=nil)
      @key = arg unless arg.nil?
      @key ||= load_key
    end

    def load_key
      @key = self.class.load_secret(secret)
    end

    def self.load_secret(path=nil)
      path ||= Chef::Config[:encrypted_data_bag_secret]

      unless path
       raise ArgumentError, "No secret specified and no secret found."
      end

      key = case path
            when /^\w+:\/\// # Remove key
              begin
                Kernel.open(path).read.strip
              rescue Errno::ECONNREFUSED
                raise ArgumentError, "Remove key not available from '#{path}'"
              rescue OpenURI::HTTPError
                raise ArgumentError, "Remove key not found at '#{path}'"
              end
            else
              unless File.exist?(path)
                raise Errno::ENOENT, "file not found '#{path}'"
              end
              IO.read(path).strip
            end

      if key.size < 1
        raise ArgumentError, "invalid zero length path in '#{path}'"
      end

      key
    end

    #
    # Wrapper for raw_data encryption settings
    # - always ensure that encryption hash is present
    # - always ensure encryption settings have defaults
    #

    def encryption(arg=nil)
      @raw_data[:encryption] ||= {}
      @raw_data[:encryption] = arg unless arg.nil?
      encryption = @raw_data[:encryption]
      encryption[:iv] = nil if encryption[:iv].nil?
      encryption[:cipher] = "aes-256-cbc" if encryption[:cipher].nil?
      encryption[:encoded_fields] = [] if encryption[:encoded_fields].nil?
      encryption
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
      super data
      encryption
      decode_data!
    end

    #
    # Determine whether the data is encoded or not
    # - yeah, it's pretty naive
    #

    def encoded?
      not encryption[:encoded_fields].empty?
    end

    #
    # Fields we wish to encode
    # - this differs from encryption[:encoded_fields] and will get merged
    #   into the latter upon an encode
    #

    def encode_fields(arg=nil)
      arg = Array(arg).uniq if arg
      set_or_return(:encode_fields, arg, kind_of: Array).uniq
    end

    #
    # Encoder / Decoder
    #

    def decode_data!
      #
      # Ensure that we save previously encoded fields into our list of fields
      # we wish to encode next time
      #
      encode_fields.concat(encryption[:encoded_fields]).uniq!
      @raw_data = decoded_data if encoded?
      @raw_data
    end

    def decoded_data
      data = Decryptor.new(raw_data, encryption, key).for_decrypted_item
      data[:encryption][:encoded_fields] = []
      data
    end

    def encode_data!
      @raw_data = encoded_data
    end

    def encoded_data
      #
      # When encoding data we'll merge those fields already encoded during
      # the previous state, found in encryption[:encoded_fields] with those
      # which we wish to encode
      #
      encryption = self.encryption.dup
      encryption[:encoded_fields] = @encode_fields.
        concat(encryption[:encoded_fields]).uniq
      Encryptor.new(raw_data, encryption, key).for_encrypted_item
    end

    #
    # Transitions
    #

    def self.from_hash(h, key=nil)
      item = new(key)
      item.raw_data = h
      item
    end

    def self.from_item(h, key=nil)
      item = self.from_hash(h.to_hash, key)
      item.data_bag h.data_bag
      item
    end

    def to_hash(encoded = true)
      result = encoded ? encoded_data : decoded_data
      result["chef_type"] = "data_bag_item"
      result["data_bag"] = self.data_bag
      result
    end

    def to_json(*a)
      result = {
        name: self.object_name,
        json_class: "Chef::DataBagItem",
        chef_type: "data_bag_item",
        data_bag: self.data_bag,
        raw_data: encoded_data
      }
      result.to_json(*a)
    end
  end
end

