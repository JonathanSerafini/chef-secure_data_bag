
class Chef
  module DSL
    module DataQuery
      def secure_data_bag_item(bag, item)
        DataBag.validate_name!(bag.to_s)
        SecureDataBag::Item.validate_id!(item)
        SecureDataBag::Item.load(bag, item)
      rescue Exception
        Log.error("Failed to load secure data bag item: #{bag.inspect} #{item.inspect}")
        raise
      end

      def secure_data_bag_item!(item, fields=[])
        secure = SecureDataBag::Item.from_item item
        secure.encoded_fields.concat(Array(fields))
        secure
      end
    end
  end
end


