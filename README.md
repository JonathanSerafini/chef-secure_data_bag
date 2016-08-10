# SecureDataBag
--------

A gem which provides a mechanism to partially encrypt data\_bag\_items on a per-key basis and which also supports both regular DataBagItem and EncryptedDataBagItem.

When specifying keys to encrypt, the library will recursively walk through the data bag content searching for encryption candidates.

## Installation
--------

Add this line to your application's Gemfile:

```
gem 'secure_data_bag'
```

And then execute:

```
$ bundle
```

Or install it yourself:

```
$ gem install secure_data_bag
```

## Usage
--------

For the most part, this behaves exactly like a standard DataBagItem would. Encryption and Decryption of attributes ought to be completely transparent.

SecureDataBagItem is also able to read either standard DataBagItem objects or EncryptedDataBagItem since the encryption mechanism is on a per-key basis and is entirely compatible with EncryptedDataBagItem's format. One caveat, however, is that SecureDataBagItem can not be read by EncryptedDataBagItem.

SecureDataBagItem is also built on Mash rather than Hash so you'll find it more compatible with symbol keys.

```
> secret_key = SecureDataBagItem.load_key("/path/to/secret")
> secret_key = nil # Load default secret

> data = { id:"databag", "encoded":"my string", "unencoded":"other string" }

> item = SecureDataBagItem.from_hash(data, encrypted_keys: [secret_key])
> item.raw_data # Unencoded hash
{ 
  id:         "databag", 
  encoded:    {
    encrypted_data: "encoded",
    cipher: aes-256-cbc,
    iv: 13453453dkgfefg==
    version: 1
  }
  unencoded:  "other string",
}

> item.to_hash
{ 
  id:         "databag", 
  chef_type:  "data_bag_item",
  data_bag:   "",
  encoded:    "my string",
  unencoded:  "other string"
}
```

A few knife commands are also provided which allow you to edit / show / from file any DataBagItem or EncryptedDataBagItem and convert them to SecureDataBag::Item format.

```
knife secure bag --help
** SECURE BAG COMMANDS **
knife secure bag edit BAG [ITEM] (options)
knife secure bag from file BAG FILE|FLDR [FILE|FLDR] (options)
knife secure bag show BAG [ITEM] (options)
```

Additionally it accepts the following command-line options :

```
--dec-format [plain|encrypted|nested]
--enc-keys FIELD1,FIELD2,FIELD3
--enc-format [plain|encrypted|nested]
--export
--export-format
--export-root PATH
```

Which may also be configured in knife.rb:

```
knife[:secure_data_bag] ||= {}
knife[:secure_data_bag][:encrypted_keys] = %w(
  password
  ssh_keys
  ssh_ids
  public_keys
  private_keys
)
knife[:secure_data_bag][:secret_file] = "#{local_dir}/secret.pem"
knife[:secure_data_bag][:export_root]= "#{kitchen_dir}/data_bags"
knife[:secure_data_bag][:export_on_upload] = false
```

#### knife secure bag show DATA_BAG DATA_BAG_ITEM

This command functions just like `knife data bag show` and is used to print out the content of either a DataBagItem, EncryptedDataBagItem or SecureDataBagItem.

By default, it will auto-detect the Item type, and print it's unencrypted version to the terminal. This behavior, however, may be altered with the following command line arguments.

- `--dec-format`: The format to decrypt the Item as. When set to *plain*, the item will not be decrypted. When set to *encrypted*, the item will be decrypted as an EncryptedDataBagItem, when set to *nested*, it will be decrypted as a SecureDataBagItem.
- `--enc-format`: This option will encrypt the Item in a given format prior to displaying it. This will default to *plain*.

Additionally, this command may be used to automatically export the data\_bag\_item to disk.

- `--export`: Enable the export feature.
- `--export-format`: The format to use when exporting this Item.

#### knife secure bag edit DATA_BAG DATA_BAG_ITEM

This command functions just like `knife data bag edit` and is used to edit either a DataBagItem, EncryptedDataBagItem or a SecureDataBagItem. It supports all of the same options as `knife secure bag show`. 

#### knife secure bag from file DATA_BAG PATH

This command functions just like `knife data bag from file` and is used to upload either a DataBagItem, EncryptedDataBagItem or a SecureDataBagItem. It supports all of the same options as `knife secure bag show`. 

#### Recipe DSL

The gem additionally provides a few Recipe DSL methods which may be useful.

```
load_secure_item = secure_data_bag_item(
  data_bag_name, 
  data_bag_item, 
  cache: false
)

load_plain_item = data_bag_item(data_bag_name, data_bag_item)
convert_plain_to_secure = secure_data_bag_item!(load_plain_item)
```
