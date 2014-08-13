
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

  class SecureDataBagItem < Chef::DataBagItem
    def initialize
      super

      @secret = nil
      @key = nil
      @cipher = nil
      @iv = nil
      @algorithm = nil
      @encoded_fields = []
      @default_encoded_fields = ["password"]
    end

    #
    # Define attributes for encryption related tasks
    #

    attr_reader :default_encoded_fields

    def secret(arg=nil)
      arg ||= Chef::Config[:encrypted_data_bag_secret] if @secret.nil?
      set_or_return(:secret, arg, kind_of: String)
    end

    def key(arg=nil)
      @key = arg unless arg.nil?
      @key ||= load_key
    end

    def load_key
      unless secret
        raise ArgumentError, "No secret specified and no secret found."
      end

      key = case secret
      when /^\w+:\/\// # Remove key
        begin
          Kernel.open(path).read.strip
        rescue Errno::ECONNREFUSED
          raise ArgumentError, "Remove key not available from '#{secret}'"
        rescue OpenURI::HTTPError
          raise ArgumentError, "Remove key not found at '#{secret}'"
        end
      else
        unless File.exist?(secret)
          raise Errno::ENOENT, "file not found '#{secret}'"
        end
        IO.read(secret).strip
      end

      if key.size < 1
        raise ArgumentError, "invalid zero length secret in '#{secret}'"
      end
      key
    end

    def cipher(arg=nil)
      arg ||= "aes-256-cbc" if @cipher.nil?
      set_or_return(:cipher, arg, kind_of: String)
    end

    def iv(arg=nil)
      set_or_return(:iv, arg, kind_of: String)
    end

    #
    # These are either the fields which are currently encoded or those that
    # we wish to encode
    #

    def encoded_fields(arg=nil)
      set_or_return(:encoded_fields, arg, kind_of: Array)
    end

    #
    # The encryption definition
    #

    def encryption
      {
        iv: iv,
        cipher: cipher,
        encoded_fields: encoded_fields + default_encoded_fields
      }
    end

    def raw_data=(enc_data)
      super enc_data
      decode_data
    end

    #
    # Encoder / Decoder
    #

    def decode_data
      if @raw_data.key? :encryption
        encryption = @raw_data.delete(:encryption) || {}

        cipher  encryption[:cipher]
        iv      encryption[:iv]
        encoded_fields  encryption[:encoded_fields]

        @raw_data = decode_data
      end
      @raw_data
    end

    def encode_data
      Encryptor.new(raw_data, encryption, key).for_encrypted_item
    end

    #
    # Transitions
    #

    def self.from_hash(h)
      m = Mash.new(h)
      item = new
      item.raw_data = m
      item
    end

    def self.from_data_bag_item(h)
      item = self.from_hash(h.to_hash)
      item.data_bag = h.data_bag
     
    end

    def to_hash
      result = encode_data
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
        raw_data: encode_data
      }
      result.to_json(*a)
    end
  end
end

