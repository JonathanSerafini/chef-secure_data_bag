
require 'chef/knife/secure_bag_base'
require 'chef/knife/data_bag_from_file'

class Chef
  class Knife
    class SecureBagFromFile < Knife::DataBagFromFile
      include Knife::SecureBagBase

      deps do
        require 'chef/data_bag'
        require 'chef/data_bag_item'
        require 'chef/knife/core/object_loader'
        require 'chef/json_compat'
        require 'secure_data_bag'
      end

      banner "knife secure bag from file BAG FILE|FLDR [FILE|FLDR] (options)"
      category "secure bag"

      option :all,
        short:  "-a",
        long:   "--all",
        description: "Upload all data bags or all items for specified databag"

      def load_data_bag_hash(hash)
        @raw_data = hash

        item = SecureDataBag::Item.from_hash(hash, secret:read_secret)
        item.to_hash
      end

      def load_data_bag_items(data_bag, items=nil)
        items ||= find_all_data_bag_items(data_bag)
        item_paths = normalize_item_paths(items)
        item_paths.each do |item_path|
          item = loader.load_from("#{data_bags_path}", data_bag, item_path)
          item = load_data_bag_hash(item)
          dbag = SecureDataBag::Item.new(secret:read_secret)
          dbag.encoded_fields encoded_fields
          dbag.raw_data = item
          dbag.data_bag(data_bag)
          dbag.save
          ui.info("Updated data_bag_item[#{dbag.data_bag}::#{dbag.id}]")
        end
      end
    end
  end
end

