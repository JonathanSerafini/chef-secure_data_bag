require 'secure_data_bag/exceptions'

module SecureDataBag
  module Encryptor
    # Instantiate an Encryptor object responsable for encrypting the
    # raw_hash with the secret.
    #
    # The optional metadata may contain hints as to how we should encrypt the
    # raw_hash. Should hints not be provided, this will do it's best to
    # detect the appropriate defaults.
    #
    # @param raw_hash [Hash] the raw hash to encrypt
    # @param secret [String] the secret to encrypt with
    # @param metadata [Hash] the optional metdata to configure the encryptor
    # @return [SecureDataBag::NestedDecryptor] the object capable of decrypting
    # @since 3.0.0
    def self.new(raw_hash, secret, metadata = {})
      metadata = Mash.new(metadata)
      format = (metadata[:encryption_format] || metadata[:decryption_format])
      case format
      when 'encrypted'
        SecureDataBag::FlatEncryptor.new(raw_hash, secret, metadata)
      else
        SecureDataBag::NestedEncryptor.new(raw_hash, secret, metadata)
      end
    end
  end

  # Encryptor object responsable for encrypting the raw_hash with the
  # secret. This object is just a wrapper around
  # Chef::EncryptedDataBagItem.
  #
  # @since 3.0.0
  class FlatEncryptor
    # The keys to encrypt
    # @since 3.0.0
    attr_reader :encrypted_keys

    # The encrypted hash generated
    # @since 3.0.0
    attr_reader :encrypted_hash

    # The decrypted hash to encrypt
    # @since 3.0.0
    attr_reader :decrypted_hash

    # The metadata used to create the encrypted_hash
    attr_reader :metadata

    # Initializer
    # @param decrypted_hash [Hash,String] the encrypted hash to encrypt
    # @param secret [String] the secret to encrypt with
    # @param metadata [Hash] optional metadata
    # @since 3.0.0
    def initialize(decrypted_hash, secret, metadata = {})
      @secret = secret
      @metadata = metadata
      @encrypted_hash = {}
      @encrypted_keys = []
      @decrypted_hash = decrypted_hash
    end

    # Method called to encrpt the data structure and return it.
    # @return [Hash] the encrypted value
    # @since 3.0.0
    def encrypt!
      @encrypted_hash = encrypt
    end

    # Method called to encrpt the data structure and return it.
    # @return [Hash] the encrypted value
    # @since 3.0.0
    def encrypt
      ## NO WORKY
      ## NO WORKY
      ## NO WORKY
      ## NO WORKY
      ## NO WORKY
      ## NO WORKY
      Chef::EncryptedDataBagItem.encrypt_data_bag_item(
        @decrypted_hash,
        @secret
      )
    end

    # Method name preserved for compatibility with
    # Chef::EncryptedDataBagItem::Encryptor.
    # @since 3.0.0
    alias :for_encrypted_item :encrypt!
  end

  # Encryptor object responsable for encrypting the raw_hash with the
  # secret. This object will recursively step through the raw_hash, looking for
  # keys matching `encrypted_keys` and encrypt their values.
  #
  # @since 3.0.0
  class NestedEncryptor
    # The keys to encrypt
    # @since 3.0.0
    attr_reader :encrypted_keys

    # The encrypted hash generated
    # @since 3.0.0
    attr_reader :encrypted_hash

    # The decrypted hash to encrypt
    # @since 3.0.0
    attr_reader :decrypted_hash

    # The metadata used to create the encrypted_hash
    attr_reader :metadata

    # Initializer
    # @param decrypted_hash [Hash,String] the encrypted hash to encrypt
    # @param secret [String] the secret to encrypt with
    # @param metadata [Hash] optional metadata
    # @since 3.0.0
    def initialize(decrypted_hash, secret, metadata = {})
      @secret = secret
      @metadata = metadata
      @encrypted_hash = {}
      @encrypted_keys = case metadata[:encryption_format]
                        when 'plain' then @encrypted_keys = []
                        else metadata[:encrypted_keys] || []
                        end
      @decrypted_hash = decrypted_hash
    end

    # Method called to encrpt the data structure and return it.
    # @return [Hash] the encrypted value
    # @since 3.0.0
    def encrypt!
      @encrypted_hash = encrypt
    end

    # Method called to encrpt the data structure and return it.
    # @return [Hash] the encrypted value
    # @since 3.0.0
    def encrypt
      encrypt_data(@decrypted_hash)
    end

    # Method name preserved for compatibility with
    # Chef::EncryptedDataBagItem::Encryptor.
    # @since 3.0.0
    alias :for_encrypted_item :encrypt!

    private

    # Recursively encrypt hash values where keys match encryptable_key?
    # @param raw_hash [Hash] the hash to encrypt
    # @return [Hash] the encrypted hash
    # @since 3.0.0
    def encrypt_data(raw_hash)
      encrypted_hash = Mash.new

      raw_hash.each do |key, value|
        value = if encryptable_key?(key)
                  encrypt_value(value)
                elsif value.is_a?(Hash)
                  encrypt_data(value)
                else value
                end
        encrypted_hash[key] = value
      end

      encrypted_hash
    end

    # Determine whether the hash key should be encrypted
    # @return [Boolean]
    # @since 3.0.0
    def encryptable_key?(key)
      @encrypted_keys.include?(key)
    end

    # Encrypt a single value
    # @return [Hash] the encrypted value
    # @since 3.0.0
    def encrypt_value(value)
      Chef::EncryptedDataBagItem::Encryptor
        .new(value, @secret).for_encrypted_item
    end
  end
end
