# SecureDataBag

Provides a mechanism to partially encrypt data bag items on a per-key basis which gives us the opportunity to still search for every other field.

When specifying keys to encrypt, the library will recursively walk through the data bag content searching for encryption candidates.

## Installation

Add this line to your application's Gemfile:

    gem 'secure_data_bag'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install secure_data_bag

## Usage

For the most part, this behaves exactly like a standard DataBagItem would. Encryption and Decryption of attributes ought to be completely transparent.

SecureDataBagItem is also able to read either standard DataBagItem objects or EncryptedDataBagItem since the encryption mechanism is on a per-key basis and is entirely compatible with EncryptedDataBagItem's format. One caveat, however, is that SecureDataBagItem can not be read by EncryptedDataBagItem.

SecureDataBagItem is also built on Mash rather than Hash so you'll find it more compatible with symbol keys. 

```
> secret_key = SecureDataBagItem.load_key("/path/to/secret")
> secret_key = nil # Load default secret

> data = { id:"databag", "encoded":"my string", "unencoded":"other string" }

> item = SecureDataBagItem.from_hash(data, key: secret_key)
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

A few knife commands are also provided which allow you to create / edit / show / from file any DataBagItem or EncryptedDataBagItem and convert them to SecureDataBag::Item format.

```
knife secure bag --help
** SECURE BAG COMMANDS **
knife secure bag create BAG [ITEM] (options)
knife secure bag edit BAG [ITEM] (options)
knife secure bag from file BAG FILE|FLDR [FILE|FLDR] (options)
knife secure bag show BAG [ITEM] (options)
```

Additionally it accepts the following command-line options :

```
--secret-file /path/to/secret.pem
--secret passcode
--encoded-fields field_one,field_two,field_three
```

Which may also be configured in knife.rb:

```
knife[:secure_data_bag] = {
  fields: ["password","ssh_keys"],
  secret_file: "/path/to/secret.pem"
}
```

