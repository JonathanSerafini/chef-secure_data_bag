class Chef
  class Knife
    module SecureDataBag
      module SecretsMixin
        # Steps to execute when the mixin is include.
        # In this case specifically, add additional command line options
        # related to exporting.
        # @since 3.0.0
        def self.included(base)
          base.option :secret,
            description: 'The secret key used to (de)encrypt data bag item values',
            short: '-s SECRET',
            long: '--secret '

          base.option :secret_file,
            description: 'The secret key file used to (de)encrypt data bag item values',
            long: '--secret-file SECRET_FILE'
        end

        # The shared secret used to encrypt / decrypt data bag items
        # @return [String] the shared secret
        # @since 3.0.0
        def secret
          @secret ||= begin
            secret = load_secret
            unless secret
              ui.fatal('A secret or secret_file must be specified')
              show_usage
              exit 1
            end
            secret
          end
        end

        private

        # Path to the secret_file
        # @return [String]
        # @since 3.0.0
        def secret_file
          config[:secret_file] ||
            Chef::Config[:knife][:secure_data_bag][:secret_file]
        end

        # Load the shared secret, either from command line parameters or from
        # a file on the filesystem.
        # @return [String] the shared secret
        # @since 3.0.0
        def load_secret
          if config[:secret] then config[:secret]
          else ::SecureDataBag::Item.load_secret(secret_file)
          end
        end
      end
    end
  end
end
