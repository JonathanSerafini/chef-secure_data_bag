require 'chef/knife/data_bag_edit'
require_relative 'secure_data_bag/base_mixin'
require_relative 'secure_data_bag/export_mixin'
require_relative 'secure_data_bag/secrets_mixin'

class Chef
  class Knife
    class SecureBagEdit < Knife::DataBagEdit
      include SecureDataBag::BaseMixin
      include SecureDataBag::ExportMixin
      include SecureDataBag::SecretsMixin

      banner 'knife secure bag edit BAG [ITEM] (options)'
      category 'secure bag'

      def run
        if @name_args.length != 2
          stdout.puts 'You must supply the data bag and an item to edit.'
          stdout.puts opt_parser
          exit 1
        end

        # Load the SecureBagItem, EncryptedDataBagItem or DataBagItem
        item = load_item(@name_args[0], @name_args[1], config_metadata)
        item_metadata = item.metadata.dup
        item.encryption_format = 'plain'

        # Allow the user to modify the content
        data = item.to_hash(metadata: true)
        data[::SecureDataBag::METADATA_KEY] = item_metadata

        # Edit the hash
        edited_item = edit_hash(data)
        item_metadata = edited_item.delete(::SecureDataBag::METADATA_KEY)

        # Generate a new SecureBagItem
        item_to_save = ::SecureDataBag::Item
                       .from_hash(edited_item, item_metadata)
        item_to_save.data_bag @name_args[0]
        item_to_save['id'] = @name_args[1]

        item_to_save.save
        stdout.puts("Saved as #{@name_args[0]}[#{@name_args[1]}]")

        export!(@name_args[0], @name_args[1], item_to_save) if should_export?

        if config[:print_after]
          data_to_print = item_to_save.to_hash
          stdout.puts(Chef::JSONCompat.to_json_pretty(data_to_print))
        end
      end
    end
  end
end
