# SecureDataBag / Knife Secure Bag

Knife Secure Bag provides a consistent interface to DataBagItem, EncryptedDataBagItem as well as the custom created SecureDataBagItem while also providing a few extra handy features to help in your DataBag workflows. 

SecureDataBagItem, can not only manage your existing DataBagItems and EncryptedDataBagItems, but it also provides you with a DataBag type which enables you to selectively encrypt only some of the fields in your DataBag thus allowing you to be able to search for the remaining fields. 

## Installation

To build and install the plugin add it your Gemfile or run: 

```shell
gem install secure_data_bag
```

## Configuration

#### Knife Secure Bag

Defaults for the Knife command may be provided in your _knife.rb_ file.

```ruby
knife[:secure_data_bag][:encrypted_keys] = %w(
  password
  ssh_keys
  ssh_ids
  public_keys
  private_keys
  keys
  secret
)
knife[:secure_data_bag][:secret_file] = "#{local_dir}/secret.pem"
knife[:secure_data_bag][:export_root] = "#{kitchen_dir}/data_bags"
knife[:secure_data_bag][:export_on_upload] = true
```

To break this up:

`knife[:secure_data_bag][:encrypted_keys] = []`

When Knife Secure Bag encrypts a hash with an _encryption format_ of *nested*, it will recursively walk through the hash from the bottom up and encrypt any key found within this array.

`knife[:secure_data_bag][:secret_file]`

When encryption is required, the shared secret found at this location will be loaded. 

`knife[:secure_data_bag][:export_root]`

When exporting a data\_bag\_item, files will be created in below this root directory. Typically this would be the data\_bag folder located within your kitchen.

`knife[:secure_data_bag][:export_on_upload]`

When a data\_bag\_item is edited using `knife secure bag edit`, it may be automatically exported to the _export\_root_.

## Examples

#### Chef cookbook recipe

```ruby
metadata = {}

# Define the keys we wish to encrypt
metadata[:encrypted_keys] = %w(encoded)

# Optionally load a specific shared secret. Otherwise, the global 
# encrypted\_data\_bag\_secret will be automatically used.
secret_key = SecureDataBagItem.load_key("/path/to/secret")

# Create a hash of data to use as an exampe
raw_data = {
	id: "item", 
  data_bag: "data_bag",
	encoded: "my string", 
	unencoded: "other string"
}

# Instantiate a SecureDataBagItem from a hash
item = SecureDataBagItem.from_hash(data, metadata)

# Or more explicitely
item = SecureDataBagItem.from_hash(data, encrypted_keys: %w(encoded))

# Print the un-encrypted raw data
pp item.raw_data

# Print the un-encrypted `encoded` key
pp item['encoded']

# Print the encrypted hash as a data_bag_item hash
pp item.to_hash

=begin
{ 
  id:         "item", 
  data_bag:   "data_bag",
  encoded:    {
    encrypted_data: "encoded",
    cipher: aes-256-cbc,
    iv: 13453453dkgfefg==
    version: 1
  }
  unencoded:  "other string",
}
=end
```

## Usage

#### Knife commands

Print an DataBagItem, EncryptedDataBagItem or SecureDataBagItem, auto-detecting the encryption method used as plain text.

```shell
knife secure bag show -F js secrets secret_item
```

Print an DataBagItem, EncryptedDataBagItem or SecureDataBagItem, auto-detecting the encryption method used as a SecureDataBagItem in encrypted format.

```shell
knife secure bag show -F js secrets secret_item --enc-format nested
```

Edit an EncryptedDataBagItem, preserve it's encryption type, and export a copy to the _data\_bag_ folder in your kitchen.

```shell
knife secure bag edit secrets secret_item --export
```

## Knife SubCommands

Most of the SubCommands support the following command-line options:

`--enc-format [plain,encrypted,nested]`

Ensure that, when displaying or uploading the data\_bag\_item, we forcibly encrypt the data\_bag\_item using the specified format instead of preserving the existing format. 

In this case: 
- plain: refers to a DataBagItem
- encrypted: refers to an EnrytpedDataBagItem
- nested: refers to a SecureDataBagItem

`--dec-format [plain,encrypted,nested]`

Attempt to decrypt the data\_bag\_item using the given format rather than the auto-detected one. The only real reason to use this is when you wish to specifically select _plain_ as the format so as to not decrypt the item.

`--enc-keys key1,key2,key3`

Provide a comma delimited list of hash keys which should be encrypted when encrypting the data\_bag\_item. This list will be concatenated with any key names listed in the configuration file or which were previously encrypted. 

`--export`

Export the data\_bag\_item to json file in either of _export-format_ or _enc-format_.

`--export-format`

Overrides the encryption format only for the _export_ feature.

`--export-root`

Root directly under which a folder should exist for each _data_bag_ into which to export _data_bag_items_ as json files.

#### knife secure bag show DATA_BAG ITEM

This command functions just like `knife data bag show` and is used to print out the content of either a DataBagItem, EncryptedDataBagItem or SecureDataBagItem.

By default, it will auto-detect the Item type, and print it's unencrypted version to the terminal. This behavior, however, may be altered using the previously mentioned command line options.

#### knife secure bag edit DATA_BAG DATA_BAG_ITEM

This command functions just like `knife data bag edit` and is used to edit either a DataBagItem, EncryptedDataBagItem or a SecureDataBagItem. It supports all of the same options as `knife secure bag show`. 

#### knife secure bag from file DATA_BAG PATH

This command functions just like `knife data bag from file` and is used to upload either a DataBagItem, EncryptedDataBagItem or a SecureDataBagItem. It supports all of the same options as `knife secure bag show`. 

## Recipe DSL

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
