
require 'chef/config'

class Chef
  class Config
    config_context :knife do
      config_context :secure_data_bag do
        default :secret_file, nil
        default :encrypted_keys, nil
      end
    end
  end
end

