
require 'open-uri'
require 'chef/data_bag_item'

class Chef::SecureDataBagItem < Chef::DataBagItem
  def initialize
    super

    @decoded = false
    @secret = nil
    @key = nil
    @cipher = nil
    @iv = nil
    @algorithm = nil
    @encoded_fields = nil
  end

  attr_accessor :decoded

  def secret(arg=nil)
    if @secret.nil? and arg.nil?
      arg = Chef::Config[:encrypted_data_bag_secret]
    end

    set_or_return(:secret, arg, kind_of: String)
  end

  def key(arg=nil)
    unless arg.nil?
      @key = arg
    end

    @key ||= begin
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
  end

  def cipher(arg=nil)
    if arg.nil? and @cipher.nil?
      arg = "aes-256-cbc"
    end

    set_or_return(:cipher, arg, kind_of: String)
  end

  def iv(arg=nil)
    set_or_return(:iv, arg, kind_of: String)
  end

  def encoded_fields(arg=nil)
    set_or_return(:encoded_fields, arg, kind_of: Array, default: [])
  end

  def encryption
    {
      iv: iv,
      cipher: cipher,
      encoded_fields: encoded_fields
    }
  end

  def raw_data
    unless @decoded
      @raw_data = decode_data
    end
    @raw_data
  end

  def raw_data=(enc_data)
    super enc_data

    if @raw_data.key? :encryption
      encryption = @raw_data.delete(:encryption) || {}

      cipher  encryption[:cipher]
      iv      encryption[:iv]
      encoded_fields  encryption[:encoded_fields]

      @decoded = false
    else @decoded = true
    end
  end

  def decode_data
    Mash.new(
      Decryptor.new(@raw_data, encryption, key)
        .for_decrypted_item
    )
  end

  def encode_data
    Encryptor.new(raw_data, encryption, key).for_encrypted_item
  end

  def self.from_hash(h)
    m = Mash.new(h)
    item = new
    item.raw_data = m
    item
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
      json_class: self.class.name,
      chef_type: "data_bag_item",
      data_bag: self.data_bag,
      raw_data: encode_data
    }
    result.to_json(*a)
  end
end

