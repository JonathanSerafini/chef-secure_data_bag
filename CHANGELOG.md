secure_data_bag
======

v3.0.3
------
* Ensure that reserved data_bag_item fields id and data_bag are never encrypted

v3.0.2
------
* Resolve issue with knife from file not encrypting files correctly

v3.0.1
------
* Ensure SecureDataBagItem .to\_data and .to\_hash output plain text unless the _encrypted_ metadata key is passed. This preserves compatibility with cookbooks running v2.

v3.0.0
------
* Full rewrite of the gem
* Full rewrite of Knife commands, new CLI tools and options 

v2.2.0
------
* Add support for printing data bag items after edit via `knife secure bag edit --print-after`
* Resolve problem where `knife secure bag edit` would not encode fields

v2.1.x
-------
* Alot of initial commits ;)
