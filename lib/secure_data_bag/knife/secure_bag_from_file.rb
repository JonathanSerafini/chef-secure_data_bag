
require 'chef/knife/data_bag_from_file'

module SecureDataBag
  module Knife
    class SecureBagFromFile < DataBagFromFile
      deps do
        require 'chef/data_bag'
        require 'chef/data_bag_item'
        require 'chef/knife/core/object_loader'
        require 'chef/json_compat'
        require 'chef/encrypted_data_bag_item'
        require 'secure_data_bag'
      end

      banner "knife secure bag from file BAG FILE|FLDR [FILE|FLDR] (options)"
      category "secure bag"

      option :secret,
        short:  "-s SECRET",
        long:   "--secret",
        description: "The secret key to use to encrypt data bag item values",
        proc: Proc.new { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        long: "--secret-file SECRET_FILE",
        description: "A file containing a secret key to use to encrypt data bag item values",
        proc: Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :encode_fields,
        long: "--encode-fields FIELD1,FIELD2,FIELD3",
        description: "List of attribute keys for which to encode values",
        default: Array.new

      option :all,
        short:  "-a",
        long:   "--all",
        description: "Upload all data bags or all items for specified databag"

      def use_encryption
        use_secure_databag ? false : super
      end

      def use_secure_databag
        @raw_data["encryption"]
      end

      def load_data_bag_item(item)
        @raw_data = item.to_hash

        if use_encryption
            Chef::EncryptedDataBagItem.
              encrypt_data_bag_item(output, read_secret)
        elsif use_secure_databag
          item = SecureDataBag::SecureDataBagItem.
            from_hash(item, read_secret)
          item.encode_fields config[:encode_fields] if config[:encode_fields]
          item.encode_data
        end
      end

      def load_data_bag_items(data_bag, items=nil)
        items ||= find_all_data_bag_items(data_bag)
        item_paths = normalize_item_paths(items)
        item_paths.each do |item_path|
          item = loader.load_from("#{data_bags_path}", data_bag, item_path)
          item = load_data_bag_item(item)
          dbag = Chef::DataBagItem.new
          dbag.data_bag(data_bag)
          dbag.raw_data = item
          dbag.save
          ui.info("Updated data_bag_item[#{dbag.data_bag}::#{dbag.id}]")
        end
      end
    end
  end
end

