require 'chef/knife/data_bag_from_file'
require_relative 'secure_data_bag/base_mixin'
require_relative 'secure_data_bag/secrets_mixin'
require_relative 'secure_data_bag/defaults_mixin'

class Chef
  class Knife
    class SecureBagFromFile < Knife::DataBagFromFile
      include SecureDataBag::BaseMixin
      include SecureDataBag::SecretsMixin
      include SecureDataBag::DefaultsMixin

      deps do
        require 'chef/data_bag'
        require 'chef/data_bag_item'
        require 'chef/knife/core/object_loader'
        require 'chef/json_compat'
        require 'chef/encrypted_data_bag_item'
      end

      banner 'knife secure bag from file BAG FILE|FLDR [FILE|FLDR] (options)'
      category 'secure bag'

      def load_data_bag_items(data_bag, items = nil)
        config_defaults_for_data_bag!(data_bag)

        items ||= find_all_data_bag_items(data_bag)
        item_paths = normalize_item_paths(items)
        item_paths.each do |item_path|
          item = loader.load_from(data_bags_path, data_bag, item_path)
          item = create_item(data_bag, item_path, item, config_metadata)
          item.save
          ui.info("Updated data_bag_item[#{item.data_bag}::#{item.id}]")
        end
      end
    end
  end
end
