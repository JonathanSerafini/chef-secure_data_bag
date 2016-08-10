
require 'spec_helper'
require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'

describe SecureDataBag::Item do
  let(:key) { 'password' }
  let(:secret) { 'data/secret.pem' }
  let(:fields) { ['encoded'] }

  let(:simple_data) { { 'id' => 'test', decoded: 'decoded', encoded: 'encoded' } }
  let(:nested_data) { simple_data.merge(nested: simple_data) }

  let(:item) { SecureDataBag::Item.new(key: key, fields: fields) }

  let(:dbag_item) do
    dbag_item = Chef::DataBagItem.new
    dbag_item.raw_data = simple_data
    dbag_item
  end

  let(:simple_item) do
    simple_item = item
    simple_item.raw_data = simple_data
    simple_item
  end

  let(:nested_item) do
    nested_item = item
    nested_item.raw_data = nested_data
    nested_item
  end

  it 'encodes simple data' do
    dbag = simple_item
    data = dbag.encoded_data
    expect(data[:decoded]).to eq('decoded')
    expect(data[:encoded]).not_to eq('encoded')
    expect(data[:encoded][:encrypted_data]).not_to eq(nil)
  end

  it 'encodes nested data' do
    dbag = nested_item
    data = dbag.encoded_data
    expect(data[:nested][:decoded]).to eq('decoded')
    expect(data[:nested][:encoded]).not_to eq('encoded')
    expect(data[:nested][:encoded][:encrypted_data]).not_to eq(nil)
  end

  it 'decodes encrypted_data_bag_item' do
    edbag = Chef::EncryptedDataBagItem.encrypt_data_bag_item(dbag_item, key)
    dbag = item
    dbag.raw_data = edbag
    data = dbag.raw_data
    expect(data[:decoded]).to eq('decoded')
    expect(data[:encoded]).to eq('encoded')
  end
end
