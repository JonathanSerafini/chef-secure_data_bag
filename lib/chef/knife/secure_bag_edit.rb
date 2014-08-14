
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

        if use_encryption and @raw_data["encrypted_data"]
          item = Chef::EncryptedDataBagItem.load(item, read_secret)
        end
        
        item = SecureDataBag::SecureDataBagItem.from_item(item, read_secret)
        item.to_hash
      end

      def edit_item(item)
        output = super

        if use_secure_databag
          output = SecureDataBag::SecureDataBagItem
            .from_hash(output, read_secret).
            encode_data
        end

        output
      end
    end
  end
end

