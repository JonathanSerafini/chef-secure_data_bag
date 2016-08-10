require 'chef/knife/data_bag_show'
require_relative 'secure_data_bag/base_mixin'
require_relative 'secure_data_bag/export_mixin'
require_relative 'secure_data_bag/secrets_mixin'

class Chef
  class Knife
    class SecureBagShow < Knife::DataBagShow
      include SecureDataBag::BaseMixin
      include SecureDataBag::ExportMixin
      include SecureDataBag::SecretsMixin

      banner "knife secure bag show BAG [ITEM] (options)"
      category "secure bag"
      
      def run
        case @name_args.length
        when 2
          run_show
        when 1
          run_list
        else
          stdout.puts opt_parser
          exit(1)
        end
      end

      def run_show
        display_metadata = config_metadata.dup
        display_metadata[:encrypted_format] ||= 'plain'

        item = load_item(@name_args[0], @name_args[1], display_metadata)
        data = item.to_hash(metadata: true)
        data = format_for_display(data)

        if should_export?
          export!(@name_args[0], @name_args[1], item)
        end

        output(data)
      end

      def run_list
        data = Chef::DataBag.load(@name_args[0])
        data = format_list_for_display(data)
        output(data)
      end
    end
  end
end
