require 'chef/knife'

class Chef
  class Knife
    module SecureDataBag
      module ExportMixin
        # Steps to execute when the mixin is include.
        # In this case specifically, add additional command line options
        # related to exporting.
        # @since 3.0.0
        def self.included(base)
          base.option :export,
            description: 'Whether to export the data_bag item',
            long: '--export',
            boolean: true

          base.option :export_format,
            description: 'Format to export the data_bag_item as. If unset, this will default to the encryption format.',
            long: '--export-format [plain|encrypted|nested]'

          base.option :export_root,
            long: '--export-root PATH',
            description: 'Path containing data_bag folders and items'
        end

        # Should knife subcommands save data_bag_items to disk after uploading
        # them to the Chef server.
        # @returns [Boolean]
        # @since 3.0.0
        def should_export?
          if config[:export].nil?
            Chef::Config[:knife][:secure_data_bag][:export_on_upload]
          else
            config[:export]
          end
        end

        # Export the item to the filesystem.
        # @param data_bag [String] the data_bag to upload to
        # @param item_name [String] the data_bag_item id to upload to
        # @param item [SecureDataBag::Item] the item to upload
        # @since 3.0.0
        def export!(data_bag, item_name, item)
          item.encryption_format = export_format
          data = item.to_hash(encrypt: true)

          if export_root.nil?
            ui.fatal('Export root is not defined')
            show_usage
            exit 1
          end

          export_file_path = export_path(data_bag, item_name)
          unless ::File.directory?(::File.dirname(export_file_path))
            ui.fatal("Export directory does not exist: #{export_file_path}")
            show_usage
            exit 1
          end

          ::File.open(export_file_path, 'w') do |f|
            f.write(Chef::JSONCompat.to_json_pretty(data))
          end

          display_path = export_file_path.sub(%r{/^#{export_root}/}, '')
          stdout.puts("Exported to #{display_path}")
        end

        private

        def export_root
          config[:export_root] ||
            Chef::Config[:knife][:secure_data_bag][:export_root]
        end

        def export_path(data_bag, item_name)
          ::File.join(export_root, data_bag, item_name) + '.json'
        end

        def export_format
          config[:export_format]
        end
      end
    end
  end
end
