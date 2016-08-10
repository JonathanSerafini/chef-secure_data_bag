require 'secure_data_bag/constants'
require 'secure_data_bag/check_encrypted'

module SecureDataBag
  module Decryptor
    # Instantiate an Decryptor object responsable for decrypting the 
    # encrypted_hash with the secret. As much as possible, this method will 
    # attempt to auto-detect the item format to ensure compatibility.
    #
    # Much like with upstream, call #for_encrypted_item on the resulting 
    # object to decrypt and deserialize it.
    #
    # @param encrypted_hash [Hash] the encrypted hash to decrypt
    # @param secret [String]
    # @param metadata [Hash] the optional metdata to configure the decryptor
    # @return [SecureDataBag::NestedDecryptor] the object capable of decrypting
    # @since 3.0.0
    def self.for(encrypted_hash, secret, metadata = {})
      metadata = Mash.new(metadata)
      NestedDecryptor.new(encrypted_hash, secret, metadata)
    end
  end

  # Decryptor object responsable for decrypting the encrypted_hash with the 
  # secret. This functions similarly, to how 
  # Chef::EncryptedDataBagItem::Decryptor does, with the caveat that this
  # is meant to decrypt entire objects and not single values. 
  # 
  # @since 3.0.0
  class NestedDecryptor
    include SecureDataBag::CheckEncrypted

    # The encrypted hash received
    # @since 3.0.0
    attr_reader :encrypted_hash

    # The keys found that had to be decrypted in the hash
    # @since 3.0.0
    attr_reader :decrypted_keys

    # The decrypted hash
    # @since 3.0.0
    attr_reader :decrypted_hash

    # The format of this DataBagItem.
    # May be one of:
    # - encrypted refers to an EncryptedDataBagItem
    # - nested refers to a SecureDataBagItem with nested values
    # - plain refers to a plain DataBagItem
    # @since 3.0.0
    attr_reader :format

    # Initializer
    # @param encrypted_hash [Hash,String] the encrypted hash to decrypt
    # @param secret [String] the secret to decrypt with
    # @param metadata [Hash] the optional metdata to configure the decryptor
    # @since 3.0.0
    def initialize(encrypted_hash, secret, metadata = {})
      @secret = secret

      @decrypted_keys = []
      @encrypted_hash = encrypted_hash
      @decrypted_hash = {}

      @format = metadata[:decryption_format] ||
        if @encrypted_hash.key?(SecureDataBag::METADATA_KEY)
          'nested'
        elsif encrypted?(@encrypted_hash)
          'encrypted'
        elsif partially_encrypted?(@encrypted_hash)
          'nested'
        else
          'plain'
        end
    end

    # Method called to decrypt the data structure and return it.
    # @return [Mix] the unencrypted value
    # @since 3.0.0
    def decrypt!
      @decrypted_hash = decrypt
    end

    # Method called to decrypt the data structure and return it.
    # @return [Mix] the unencrypted value
    # @since 3.0.0
    def decrypt
      decrypt_data(@encrypted_hash)
    end

    # Method name preserved for compatibility with 
    # Chef::EncryptedDataBagItem::Decryptor.
    # @since 3.0.0
    alias :for_decrypted_item :decrypt!

    private

    # Decrypt a possibly encrypted value
    # @param raw_hash [Hash] a potentially encrypted hash
    # @return [Hash] the unencrypted value
    # @since 3.0.0
    def decrypt_data(raw_hash)
      if looks_like_encrypted?(raw_hash)
        decrypt_value(raw_hash)
      else
        decrypt_hash(raw_hash)
      end
    end

    # Decrypt a hash potentially containing nested encrypted values
    #
    # Additionally, this method will attempt tovkeep track of the names of 
    # each encrypted key.
    #
    # @param hash [Hash] a potentially encrypted hash
    # @return [Hash] the unencrypted value
    # @since 3.0.0
    def decrypt_hash(hash)
      decrypted_hash = Mash.new

      hash.each do |key, value|
        value = if looks_like_encrypted?(value)
                  @decrypted_keys.push(key) unless @decrypted_keys
                                                   .include?(key)
                  #pp @format + ' -- ' + decrypt_value(value).class
                  decrypt_value(value)
                elsif value.is_a?(Hash)
                  decrypt_hash(value)
                else value
                end
        decrypted_hash[key] = value
      end

      decrypted_hash
    end

    # Decrypt an encrypted value
    # @param hash [Hash] the encrypted value as a hash
    # @return [Mix] the unencrypted value
    # @since 3.0.0
    def decrypt_value(value)
      case @format
      when 'plain' then value
      else
        Chef::EncryptedDataBagItem::Decryptor
          .for(value, @secret).for_decrypted_item
      end
    end
  end
end
