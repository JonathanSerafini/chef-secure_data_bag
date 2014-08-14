
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
            proc: Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

          option :encode_fields,
            long: "--encode-fields FIELD1,FIELD2,FIELD3",
            description: "List of attribute keys for which to encode values",
            default: Array.new
        end
      end
      
      def use_encryption
        @raw_data["encrypted_data"] ? super : false
      end

      def use_secure_databag
        @raw_data["encryption"]
      end
    end
  end
end

