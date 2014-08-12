# SecureDataBag

Provides a mechanism to partially encrypt data bag items on a per-key basis which gives us the opportunity to still search for every other field.

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
data = { id:"databag", "value":"my string" }
item = SecureDataBagItem.from_hash(data)
item.raw_data
item.encoded_fields ["value"]
item.to_hash
```

By default, this will use the system wide secret file. But this can be changed.

```
item.secret "/path/to/file.pem"
item.secret "uri://path/to/file.pem"
item.cipher "aes-256-cbc"
```

