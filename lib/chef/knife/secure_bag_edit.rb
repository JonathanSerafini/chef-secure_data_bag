
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

        item = SecureDataBag::Item.from_item(item, key:read_secret)
        hash = item.to_hash(encoded: false)
        hash = data_for_edit(hash)
        hash
      end

      def edit_item(item)
        output = super
        output = data_for_save(output)

        item = SecureDataBag::Item.from_hash(output, key:read_secret)
        item.encoded_fields encoded_fields
        item.to_hash encoded:true
      end
    end
  end
end

