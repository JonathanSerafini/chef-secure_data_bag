
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
          Chef::EncryptedDataBagItem.load(item, read_secret).to_hash
        elsif use_secure_databag
          SecureDataBag::SecureDataBagItem.from_item(output, read_secret)
        else
          item
        end
      end

      def edit_item(item)
        output = super

        if use_secure_databag
          output = SecureDataBag::SecureDataBagItem
            .from_item(output, read_secret).
            encode_Data
        end
      end
    end
  end
end

