
require 'yaml'
require 'ffi_yajl'
require 'openssl'
require 'base64'
require 'digest/sha2'

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

  def encrypted_bytes(data)
    Base64.decode64(data)
  end

  def iv
    Base64.decode64(@encryption["iv"])
  end

  def decrypted_hash
    @decrypted_hash ||= begin
      data = encrypted_hash.dup
      @encryption["encoded_fields"].each do |field|
        data[field] = decrypted_value(data[field])
      end

      data
    rescue OpenSSL::Cipher::CipherError => e
      raise DecryptionFailure, decryption_error(e)
    end
  end

  def decrypted_value(value)
    value = encrypted_bytes(value)
    value = openssl_decryptor(value)
    value << openssl_decryptor.final
    @openssl_decryptor = nil # Apparently it's single use
    value
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
    requested_cipher = @encryption["cipher"]
    unless requested_cipher == ALGORITHM
      raise UnsupportedCipher, 
        "Cipher '#{requested_cipher}' is not supported by this version of Chef. Available ciphers: ['#{ALGORITHM}']"
    end
  end
end

