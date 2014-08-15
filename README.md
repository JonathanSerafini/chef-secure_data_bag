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

SecureDataBagItem is also built on Mash rather than Hash so you'll find it more compatible with symbol keys. 

```
> secret_key = SecureDataBagItem.load_key("/path/to/secret")
> secret_key = nil # Load default secret

> data = { id:"databag", "encoded":"my string", "unencoded":"other string" }

> item = SecureDataBagItem.from_hash(data, secret_key)
> item.raw_data # Unencoded hash with data[:encryption] added
{ 
  id:         "databag", 
  encoded:    "my string",
  unencoded:  "other string", 
  encryption:{
    cipher:"aes-256-cbc",
    iv:nil,
    encoded_fields:[] 
  }
}

> item.to_hash
{ 
  id:         "databag", 
  chef_type:  "data_bag_item",
  data_bag:   "",
  encoded:    "my string",
  unencoded:  "other string", 
  encryption:{
    cipher:"aes-256-cbc",
    iv:nil,
    encoded_fields:[] 
  }
}

> item.encode_fields ["encoded"]
> item.to_hash # Encoded hash compatible with DataBagItem
{ 
  id:         "databag", 
  chef_type:  "data_bag_item",
  data_bag:   "",
  encoded:    "[encoded]",
  unencoded:  "other string", 
  encryption:{
    cipher:"aes-256-cbc",
    iv:nil,
    encoded_fields:["encoded"]
  }
}

> item.raw_data
{ 
  id:         "databag", 
  chef_type:  "data_bag_item",
  data_bag:   "",
  encoded:    "my string",
  unencoded:  "other string", 
  encryption:{
    cipher:"aes-256-cbc",
    iv:nil,
    encoded_fields:[] 
  }
}

```

A few knife commands are also provided which allow you to create / edit / show / from file any DataBagItem or EncryptedDataBagItem and convert them to SecureDataBag::Item format.

```
knife secure bag create data_bag item

knife secure bag edit data_bag item

knife secure bag show data_bag item

knife secure bag from file data_bag /path/to/item.json
```

