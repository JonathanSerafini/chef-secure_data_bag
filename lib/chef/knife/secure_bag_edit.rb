
require 'chef/knife/secure_bag_base'
require 'chef/knife/data_bag_edit'

class Chef
  class Knife
    class SecureBagEdit < Knife::DataBagEdit
      include Knife::SecureBagBase

      banner "knife secure bag edit BAG [ITEM] (options)"
      category "secure bag"

      def load_item(bag, item_name)
        item = Chef::DataBagItem.load(bag, item_name)
        @raw_data = item.to_hash

        if use_encryption
          item = Chef::EncryptedDataBagItem.load(item, read_secret)
        end

        item = SecureDataBag::Item.from_item(item, read_secret)
        hash = item.to_hash(false)
        # 
        # Ensure that we display encoded_fields
        # - generally this would be blank given that all fields are decrypted
        #
        hash[:encryption][:encoded_fields] = encoded_fields_for(item)
        hash
      end

      def edit_item(item)
        output = super

        #
        # Store the desired fields to encode and set to hash to unencrypted
        # until we have created the object
        #
        encode_fields = output["encryption"]["encoded_fields"]
        output["encryption"]["encoded_fields"] = []

        item = SecureDataBag::Item.from_hash(output, read_secret)
        item.encode_fields encode_fields
        item.to_hash
      end
    end
  end
end

