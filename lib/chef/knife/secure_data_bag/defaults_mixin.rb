require 'chef/knife'

class Chef
  class Knife
    module SecureDataBag
      module DefaultsMixin
        # Apply Knife config values defined in knife.rb
        # @param data_bag [String] the data_bag name
        # @since 3.0.0
        def config_defaults_for_data_bag!(data_bag)
          config_defaults_for_data_bags(data_bag).each do |key, value|
            if options.key?(key.to_sym)
              config[key.to_sym] ||= value
            end
          end
        end

        private 

        # Defaults configuration hash for a specific data_bag
        # @param data_bag [String] the data_bag name
        # @return [Hash] the configuration hash
        # @since 3.0.0
        def config_defaults_for_data_bags(data_bag)
          defaults = Chef::Config[:knife][:secure_data_bag] || {}
          defaults = defaults[:defaults] || {}
          defaults[data_bag.to_sym] || {}
        end
      end
    end
  end
end
