
require 'yaml'
require 'yajl'
require 'openssl'
require 'base64'
require 'digest/sha2'

module SecureDataBag
  class SecureDataBagItem
    class Encryptor
      attr_reader :encryption
      attr_reader :unencrypted_hash
      attr_reader :encoded_fields
      attr_reader :key

      def initialize(unencrypted_hash, encryption, key)
        @encryption = encryption
        @unencrypted_hash = unencrypted_hash
        @encoded_fields = []
        @key = key
      end

      def for_encrypted_item
        data = encrypted_hash
        encryption_hash = encryption.dup
        encryption_hash[:iv] = Base64.encode64(encryption_hash[:iv] || "")
        encryption_hash[:encoded_fields] = encoded_fields.uniq
        data.merge({encryption:encryption_hash})
      end

      def encrypted_hash
        @encrypted_data ||= begin
          encrypt_hash(unencrypted_hash.dup) 
        end
      end

      def encrypt_hash(hash)
        hash.each do |k,v|
          if encryption[:encoded_fields].include?(k)
            v = encrypt_value(v)
            encoded_fields << k
          elsif v.is_a? Hash
            v = encrypt_hash(v)
          end
          hash[k] = v
        end
        hash
      end

      def encrypt_value(value)
        value = normalize_value(value)

        if not value.nil? and not value.empty?
          value = openssl_encryptor.update(value)
          value << openssl_encryptor.final
          @openssl_encryptor = nil
          value = Base64.encode64(value)
        end

        value
      end

      def normalize_value(value)
        if [Hash,Array].any? {|c| value.is_a? c}
          serialize_value(value)
        else 
          value.to_s
        end
      end

      def serialize_value(value)
        Yajl::Encoder.encode(:json_wrapper => value)
      end

      def openssl_encryptor
        @openssl_encryptor ||= begin
          encryption[:iv] = nil if encryption[:iv].empty?
          encryptor = OpenSSL::Cipher::Cipher.new(encryption[:cipher])
          encryptor.encrypt
          encryption[:iv] ||= encryptor.random_iv
          encryptor.iv = encryption[:iv]
          encryptor.key = Digest::SHA256.digest(key)
          encryptor
        end
      end
    end
  end
end

