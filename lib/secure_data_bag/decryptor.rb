
require 'yaml'
require 'ffi_yajl'
require 'openssl'
require 'base64'
require 'digest/sha2'

module SecureDataBag
  class SecureDataBagItem
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
        pp "decrypted_hash"
        decrypted_hash
      end

      def decryption_error(e=nil)
        msg = "Error decrypting data bag value"
        msg << ": '#{e.message}'" if e
        msg << ". Most likely the provided key is incorrect"
        msg
      end

      def iv
        @iv ||= begin
          iv_string = encryption[:iv]
          Base64.decode64(iv_string)
        end
      end

      def decrypted_hash
        @decrypted_hash ||= begin
          decrypt_hash(encrypted_hash.dup)
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
          value = openssl_decryptor.update(value)
          value << openssl_decryptor.final

          if value.include? "json_wrapper"
            value = FFI_Yajl::Parser.parse(value)["json_wrapper"]
          end
          @openssl_decryptor = nil
        end
        value
      end

      def openssl_decryptor
        @openssl_decryptor ||= begin
          d = OpenSSL::Cipher::Cipher.new(encryption[:cipher])
          d.decrypt
          d.key = Digest::SHA256.digest(key)
          d.iv = iv
          d
        end
      end
    end
  end
end

