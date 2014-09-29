
require 'chef/knife/secure_bag_base'
require 'chef/knife/data_bag_show'

class Chef
  class Knife
    class SecureBagShow < Knife::DataBagShow
      include Knife::SecureBagBase

      banner "knife secure bag show BAG [ITEM] (options)"
      category "secure bag"

      def load_item(bag, item_name)
        item = SecureDataBag::Item.load(
          bag, item_name, 
          key: read_secret,
          fields: encoded_fields
        )

        data = item.to_hash(encoded:false)
        data = data_for_edit(data)
        data
      end

      def run
        display = case @name_args.length
                  when 2
                    item = load_item(@name_args[0], @name_args[1])
                    display = format_for_display(item)
                  when 1
                    format_list_for_display(Chef::DataBag.load(@name_args[0]))
                  else
                    stdout.puts opt_parser
                    exit(1)
                  end
        output(display)
      end
    end
  end
end

