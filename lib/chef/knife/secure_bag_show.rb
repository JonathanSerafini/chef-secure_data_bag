
require 'chef/knife/secure_bag_base'
require 'chef/knife/data_bag_show'

class Chef
  class Knife
    class SecureBagShow < Knife::DataBagShow
      include Knife::SecureBagBase

      banner "knife secure bag show BAG [ITEM] (options)"
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

      def run
        item = load_item(@name_args[0], @name_args[1])
        display = format_for_display(item)
        output(display)
      end
    end
  end
end

