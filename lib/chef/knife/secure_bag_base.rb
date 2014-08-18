
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
            default: ""
        end
      end
     
      def encode_fields_to_array
        unless config[:encode_fields].is_a?(Array)
          config[:encode_fields] = config[:encode_fields].split(",")
        end
      end

      def use_encryption
        if use_secure_databag then false
        else
          if @raw_data["encrypted_data"] or
              @raw_data.reject { |k,v| k == "id" }.
              all? { |k,v| v.is_a?(Hash) and v.key? "encrypted_data" }
          then super
          else false
          end
        end
      end

      def use_secure_databag
        @raw_data["encryption"]
      end

      def encoded_fields_for(item)
        [].concat(config[:encode_fields].split(",")).
          concat(item.encode_fields).
          uniq
      end

      def require_secret
        if not config[:secret] and not config[:secret_file]
          show_usage
          ui.fatal("A secret or secret_file must be specified")
          exit 1
        end
      end

    end
  end
end

