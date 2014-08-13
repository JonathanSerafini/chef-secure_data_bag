
require 'chef/encrypted_data_bag_item/decryptor'
require 'chef/encrypted_data_bag_item/decryption_failure'
require 'chef/encrypted_data_bag_item/unsupported_cipher'

class Decryptor
  attr_reader :key
  attr_reader :encryption
  attr_reader :encrypted_hash

  def initialize(encrypted_hash, encryption, key)
    @encryption = encryption
    @encrypted_hash = encrypted_hash
    @key = key
  end

  def for_decrypted_item
    FFI_Yajl::Parser.parse(decrypted_hash)["json_wrapper"]
  rescue FFI_Yajl::ParseError
    raise DecryptionFailure, decryption_error
  end

  def decryption_error(e=nil)
    msg = "Error decrypting data bag value"
    msg << ": '#{e.message}'" if e
    msg << ". Most likely the provided key is incorrect"
    msg
  end

  def iv
    Base64.decode64(encryption[:iv])
  end

  def decrypted_hash
    @decrypted_hash ||= begin
      decrypt_hash(decrypted_hash.dup)
    end
  end

  def decrypt_hash(hash)
    hash.each do |k,v|
      if encryption[:encoded_fields].include?(k)
        v = decrypt_value(v)
      elsif v.is_a? Hash
        v = decrypt_hash(v)
      end
      hash[k] = v
    end
    hash
  end

  def decrypt_value(value)
    if value.is_a? String and not value.empty?
      value = Base64.decode64(value)
      value = openssl_decryptor(value)
      value << openssl_decryptor.final
      value = FFI_Yajl::Parser.parse(value)["json_wrapper"]
      @openssl_decryptor = nil
    end
    value
  rescue OpenSSL::Cipher::CipherError => e
    raise DecryptionFailure, decryption_error(e)
  end

  def openssl_decryptor
    @openssl_decryptor ||= begin
      assert_valid_ciper!
      d = OpenSSL::Cipher::Cipher.new(ALGORITHM)
      d.decrypt
      d.key = Digest::SHA256.digest(key)
      d.iv = iv
      d
    end
  end

  def assert_valid_cipher!
    requested_cipher = encryption[:cipher]
    unless requested_cipher == encryption[:cipher]
      raise UnsupportedCipher, "Cipher '#{requested_cipher}' is not supported by this version of Chef. Available ciphers: ['#{ALGORITHM}']"
    end
  end
end

