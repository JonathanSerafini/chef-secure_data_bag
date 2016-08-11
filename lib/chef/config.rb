require 'chef/config'

class Chef
  class Config
    config_context :knife do
      config_context :secure_data_bag do
        config_context :export_metadata do
        end
      end
    end
  end
end
