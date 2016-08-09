
require 'chef/knife/secure_bag_base'
require 'chef/knife/data_bag_edit'

class Chef
  class Knife
    class SecureBagEdit < Knife::DataBagEdit
      include Knife::SecureBagBase

      banner "knife secure bag edit BAG [ITEM] (options)"
      category "secure bag"

      def load_item(bag, item_name)
        item = SecureDataBag::Item.load(bag, item_name)
        hash = item.to_hash(encoded: false)
        hash["_encoded_keys"] = item.encoded_keys
        hash
      end

      def run
        if @name_args.length != 2
          stdout.puts "You must supply the data bag and an item to edit!"
          stdout.puts opt_parser
          exit 1
        end

        # Load the SecureBagItem, EncryptedDataBagItem or DataBagItem
        item = load_item(@name_args[0], @name_args[1])

        # Allow the user to modify the content
        edited_item = edit_hash(item)

        # Fetch the keys that are to be encoded
        keys_to_encode = edited_item.delete("_encoded_keys")
        if keys_to_encode and not keys_to_encode.empty?
          ui.info("Saving with secure keys: #{keys_to_encode.join(", ")}")
        else
          ui.info("Saving without any secure keys")
        end

        # Generate a new SecureBagItem
        item_to_save = SecureDataBag::Item.new(
          data: edited_item,
          keys: keys_to_encode
        )
        item_to_save.data_bag @name_args[0] # Set data_bag to match initial
        item_to_save["id"] = @name_args[1]     # Ensure id was not changed
        item_to_save.save

        stdout.puts("Saved data_bag_item[#{@name_args[1]}]")

        if config[:print_after]
          data_to_print = item_to_save.to_hash(encoded: true)
          ui.output(Chef::JSONCompat.to_json_pretty(data_to_print))
        end
      end
    end
  end
end

