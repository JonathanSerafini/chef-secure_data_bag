
require "chef/dsl/data_query"
Chef::DSL::DataQuery.send(:include, SecureDataBag::DSL::DataQuery)

