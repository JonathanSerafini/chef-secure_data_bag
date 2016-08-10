require 'chef/encrypted_data_bag_item/check_encrypted'

module SecureDataBag
  # Common code for checking if a data bag appears encrypted
  module CheckEncrypted
    include Chef::EncryptedDataBagItem::CheckEncrypted

    # Autodetect whether the item's raw hash appears to be encrypted
    def partially_encrypted?(raw_data)
      data = raw_data.reject { |k, _| k == 'id' }

      # Detect whether any of the raw hash keys, or their nested structures
      # contain encrypted values.
      data.any? do |_, v|
        looks_like_partially_encrypted?(v)
      end
    end

    private

    # Chef if any of the nested data structures look like they have been
    # encrypted in a manner compatible with
    # Chef::EncryptedDataBagItem::Encryptor::VersionXEncryptor.
    def looks_like_partially_encrypted?(data)
      return false unless data.is_a?(Hash)
      looks_like_encrypted?(data) || partially_encrypted?(data)
    end
  end
end
