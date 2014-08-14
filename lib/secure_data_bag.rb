
module SecureDataBag
end

require "secure_data_bag/version"
require "secure_data_bag/secure_data_bag_item.rb"
require "secure_data_bag/decryptor.rb"
require "secure_data_bag/encryptor.rb"

class Chef
  module DSL
    module DataQuery
      def secure_data_bag_item(bag, item)
        DataBag.validate_name!(bag.to_s)
        SecureDataBagItem.validate_id!(item)
        SecureDataBagItem.load(bag, item)
      rescue Exception
        Log.error("Failed to load secure data bag item: #{bag.inspect} #{item.inspect}")
        raise
      end

      def secure_data_bag_item!(item, fields=[])
        secure = SecureDataBag::SecureDataBagItem.from_item item
        secure.encode_fields secure.encode_fields + fields
        secure
      end
    end
  end
end

