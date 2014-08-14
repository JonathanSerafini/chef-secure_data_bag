
require 'chef/knife/data_bag_edit'

module SecureDataBag
  module Knife
    class SecureBagEdit < DataBagEdit
      deps do
        require 'chef/data_bag'
        require 'chef/encrypted_data_bag_item'
        require 'secure_data_bag'
      end

      banner "knife secure bag edit BAG [ITEM] (options)"
      category "secure bag"

      option :secret,
        short:  "-s SECRET",
        long:   "--secret",
        description: "The secret key to use to encrypt data bag item values",
        proc: Proc.new { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        long: "--secret-file SECRET_FILE",
        description: "A file containing a secret key to use to encrypt data bag item values",
        proc: Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

      def use_encryption
        use_secure_databag ? false : super
      end

      def use_secure_databag
        @raw_data["encryption"]
      end

      def load_item(bag, item_name)
        item = Chef::DataBagItem.load(bag, item_name)
        @raw_data = item.to_hash

        if use_encryption
          Chef::EncryptedDataBagItem.load(item, read_secret).to_hash
        elsif use_secure_databag
          SecureDataBag::SecureDataBagItem.from_item(output, read_secret)
        else
          item
        end
      end

      def edit_item(item)
        output = super

        if use_secure_databag
          output = SecureDataBag::SecureDataBagItem
            .from_item(output, read_secret).
            encode_Data
        end
      end
    end
  end
end

