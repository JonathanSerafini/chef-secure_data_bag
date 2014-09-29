
require 'chef/knife'

class Chef
  class Knife
    module SecureBagBase
      def self.included(includer)
        includer.class_eval do
          deps do
            require 'secure_data_bag'
          end
        
          option :secret,
            short:  "-s SECRET",
            long:   "--secret",
            description: "The secret key to use to encrypt data bag item values",
            proc: Proc.new { |s| Chef::Config[:knife][:secret] = s }

          option :secret_file,
            long: "--secret-file SECRET_FILE",
            description: "A file containing a secret key to use to encrypt data bag item values",
            proc: Proc.new { |sf| 
              Chef::Config[:encrypted_data_bag_secret] = sf 
            }

          option :secure_data_bag_fields,
            long: "--encoded-fields FIELD1,FIELD2,FIELD3",
            description: "List of attribute keys for which to encode values",
            proc: Proc.new { |o|
              Chef::Config[:knife][:secure_data_bag][:fields] = o.split(",")
            }
        end
      end

      def encoded_fields(arg=nil)
        config[:secure_data_bag_fields] = arg unless arg.nil?
        config[:secure_data_bag_fields] || 
          Chef::Config[:knife][:secure_data_bag][:fields]
      end

      def secret_file
        config[:secret] ||
          Chef::Config[:knife][:secure_data_bag][:secret_file] ||
          Chef::Config[:encrypted_data_bag_secret]
      end

      def use_encryption
        true
      end

      def read_secret
        if config[:secret] then config[:secret]
        else SecureDataBag::Item.load_secret(secret_file)
        end
      end

      def require_secret
        if not config[:secret] and not secret_file
          show_usage
          ui.fatal("A secret or secret_file must be specified")
          exit 1
        end
      end

      def data_for_create(hash={})
        hash[:id] = @data_bag_item_name
        hash = data_for_edit(hash)
        hash
      end

      def data_for_edit(hash)
        hash[:_encoded_fields] = encoded_fields
        hash
      end

      def data_for_save(hash)
        @encoded_fields = hash.delete(:_encoded_fields)
        hash
      end

    end
  end
end

