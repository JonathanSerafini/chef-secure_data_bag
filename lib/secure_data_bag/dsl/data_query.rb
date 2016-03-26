
module SecureDataBag
  module DSL
    module DataQuery
      def secure_data_bag_item(bag, item, cache: false)
        data_bag_item = begin
          node.run_state[:secure_data_bag] ||= {}
          node.run_state[:secure_data_bag][bag] ||= {}
          node.run_state[:secure_data_bag][bag][item]
        end if cache

        data_bag_item ||= begin
          Chef::DataBag.validate_name!(bag.to_s)
          SecureDataBag::Item.validate_id!(item)
          SecureDataBag::Item.load(bag, item)
        rescue Exception
          Chef::Log.error("Failed to load secure data bag item: #{bag.inspect} #{item.inspect}")
          raise
        end
      end

      def secure_data_bag_item!(item, fields=[])
        secure = SecureDataBag::Item.from_item item
        secure.encoded_fields.concat(Array(fields))
        secure
      end
    end
  end
end


