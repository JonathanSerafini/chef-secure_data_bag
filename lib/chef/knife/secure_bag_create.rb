
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
        create_object({ id: @data_bag_item_name }, 
                      "data_bag_item[#{@data_bag_item_name}]") do |output|

          item =  if use_encryption
                    item = Chef::EncryptedDataBagItem.
                      encrypt_data_bag_item(output,read_secret)
                  else
                    output
                  end

          @raw_data = item.to_hash
          if use_secure_databag or config[:encode_fields]
            item = SecureDataBag::SecureDataBagItem.
              from_item(item, read_secret).encode_data
          end

          item.data_bag(@data_bag_name)
          rest.post_rest("data/#{@data_bag_name}", item)
        end
      end

      def run
        @data_bag_name, @data_bag_item_name = @name_args

        if @data_bag_name.nil?
          show_usage
          ui.fatal("You must specify a data bag name")
          exit 1
        end

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

