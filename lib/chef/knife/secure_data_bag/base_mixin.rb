require 'chef/knife'

class Chef
  class Knife
    module SecureDataBag
      module BaseMixin
        # Steps to execute when the mixin is include.
        # In this case specifically, add additional command line options
        # related to exporting.
        # @since 3.0.0
        def self.included(base)
          base.deps do
            require 'secure_data_bag'
          end

          base.option :encryption_format,
            description: 'The format with which to encrypt data. If unset, it will be autodetected.',
            long: '--enc-format [plain|encrypted|nested]'

          base.option :decryption_format,
            description: 'The format with which to decrypt data. If unset, it will be autodetected.',
            long: '--dec-format [plain|encrypted|nested]'

          base.option :encrypted_keys,
            description: 'Comma delimited list of keys which should be encrypted, in addition to what was previously there',
            long: '--enc-keys FIELD1,FIELD2,FIELD3',
            proc: Proc.new { |s| s.split(',') }
        end

        # Metadata to use when interacting with SecureDataBag containing
        # overrides specified on the command-line.
        # @since 3.0.0
        def config_metadata
          Mash.new({
            encryption_format: config[:encryption_format],
            decryption_format: config[:decryption_format],
            encrypted_keys: encrypted_keys
          })
        end

        # Load a data_bag_item from Chef Server
        # @param data_bag [String] the data_bag to load from
        # @param item_name [String] the data_bag_item name to load
        # @param metadata [Hash] the optional metadata to pass to ::Item
        # @return [SecureDataBag::Item]
        # @since 3.0.0
        def load_item(data_bag, item_name, metadata = {})
          item = ::SecureDataBag::Item.load(data_bag, item_name, metadata)
          item
        end

        # Create a new data_bag_item
        # @param data_bag [String] the data_bag to load from
        # @param item_name [String] the data_bag_item name to load
        # @param data [Hash] the optional raw_data to use
        # @param metadata [Hash] the optional metadata to pass to ::Item
        # @return [SecureDataBag::Item]
        # @since 3.0.0
        def create_item(data_bag, item_name, data = {}, metadata = {})
          item = ::SecureDataBag::Item.new(metadata)
          item.raw_data = data_data
          item.data_bag bag
          item
        end

        private

        # Keys to encrypt which are a result of merging the arrays found within
        # the the configuration file and provided over the command-line.
        # @since 3.0.0
        def encrypted_keys
          Array(config[:encrypted_keys]).concat(
            Array(Chef::Config[:knife][:secure_data_bag][:encrypted_keys])
          ).
          uniq
        end
      end
    end
  end
end
