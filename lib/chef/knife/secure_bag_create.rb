
require 'chef/knife/secure_bag_base'
require 'chef/knife/data_bag_create'

class Chef
  class Knife
    class SecureBagCreate < Knife::DataBagCreate
      include Knife::SecureBagBase

      banner "knife secure bag create BAG [ITEM] (options)"
      category "secure bag"

      def create_databag
        begin
          rest.post_rest("data", { name: @data_bag_name })
          ui.info("Created data_bag[#{@data_bag_name}]")
        rescue Net::HTTPServerException => e
          raise unless e.to_s =~ /^409/
          ui.info("Data bag #{@data_bag_name} already exists")
        end
      end

      def create_databag_item
        create_object(initial_data, 
                      "data_bag_item[#{@data_bag_item_name}]") do |output|

          @raw_data = data_for_save(output)

          item = SecureDataBag::Item.from_hash(@raw_data, read_secret)
          item.encoded_fields(encoded_fields)
          item.data_bag(@data_bag_name)

          rest.post_rest("data/#{@data_bag_name}", item.to_hash)
        end
      end

      def run
        @data_bag_name, @data_bag_item_name = @name_args

        if @data_bag_name.nil?
          show_usage
          ui.fatal("You must specify a data bag name")
          exit 1
        end

        require_secret

        begin
          Chef::DataBag.validate_name!(@data_bag_name)
        rescue Chef::Exceptions::InvalidDataBagName => e
          ui.fatal(e.message)
          exit(1)
        end

        # create the data bag
        create_databag

        if @data_bag_item_name
          create_databag_item
        end
      end
    end
  end
end

