
require 'chef/encrypted_data_bag_item/encryptor'
require 'chef/encrypted_data_bag_item/decryption_failure'
require 'chef/encrypted_data_bag_item/unsupported_encrypted_data_bag_item_format'

class Encryptor
  attr_reader :encryption
  attr_reader :unencrypted_hash
  attr_reader :key

  def initialize(unencrypted_hash, encryption, key)
    @encryption = encryption
    @unencrypted_hash = unencrypted_hash
    @key = key
  end

  def for_encrypted_item
    encrypted_hash.merge({encryption:encryption})
  end

  def openssl_encryptor
    @openssl_encryptor ||= begin
      encryptor = OpenSSL::Cipher::Cipher.new(encryption[:cipher])
      encryptor.encrypt
      encryption[:iv] ||= encryptor.random_iv
      encryptor.iv = encryption[:iv]
      encryptor.key = Digest::SHA256.digest(key)
      encryptor
    end
  end

  def encrypted_value(value)
    value = case value.is_a?
            when Array, Hash then serialize_value(value)
            when Fixnum then value.to_s
            else value
            end
    value = openssl_encryptor.update(value)
    value << openssl_encryptor.final
    @openssl_encryptor = nil
    Base64.encode64(value)
  end

  def encrypted_hash
    @encrypted_data ||= begin
      data = unencrypted_hash.dup
      encryption[:encoded_fields].each do |field|
        data[field] = encrypted_value(data[field])
      end
      data
    end
  end

  def serialize_value(value)
    FFI_Yajl::Encoder.encode(:json_wrapper => value)
  end
end

