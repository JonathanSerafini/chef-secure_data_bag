require 'json'
require 'chef/knife/data_bag_show'
require_relative 'secure_data_bag/base_mixin'
require_relative 'secure_data_bag/export_mixin'
require_relative 'secure_data_bag/secrets_mixin'

class Chef
  class Knife
    class SecureBagOpen < Knife::DataBagShow
      include SecureDataBag::BaseMixin
      include SecureDataBag::SecretsMixin

      banner 'knife secure bag open PATH'
      category 'secure bag'

      def run
        unless ::File.exist?(@name_args[0])
          ui.fatal('File not found.')
          show_usage
          exit 1
        end

        display_metadata = config_metadata.dup
        display_metadata[:encryption_format] ||= 'plain'

        data = File.read(@name_args[0])
        data = JSON.parse(data)
        item = create_item('local', @name_args[0], data, display_metadata)

        display_data = item.to_hash(metadata: true)
        display_data = format_for_display(display_data)

        output(display_data)
      end
    end
  end
end
