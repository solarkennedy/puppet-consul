require 'spec_helper'

describe Puppet::Type.type(:consul_token) do

  it 'should fail if no name is provided' do
    expect do
      Puppet::Type.type(:consul_token).new(:type => 'client')
    end.to raise_error(Puppet::Error, /Title or name must be provided/)
  end

  it 'should fail if accessor_id ist not a string' do
    expect do
      Puppet::Type.type(:consul_token).new(:name => 'foo', :accessor_id => {})
    end.to raise_error(Puppet::Error, /ID must be a string/)
  end

  it 'should fail if secret_id ist not a string' do
    expect do
      Puppet::Type.type(:consul_token).new(:name => 'foo', :secret_id => {})
    end.to raise_error(Puppet::Error, /ID must be a string/)
  end

  it 'should fail if policy name list is not an array' do
    expect do
      Puppet::Type.type(:consul_token).new(:name => 'foo', :policies_by_name => [[]])
    end.to raise_error(Puppet::Error, /Policy name list must be an array of strings/)
  end

  it 'should fail if policy ID list is not an array' do
    expect do
      Puppet::Type.type(:consul_token).new(:name => 'foo', :policies_by_id => [[]])
    end.to raise_error(Puppet::Error, /Policy ID list must be an array of strings/)
  end

  context 'with name defined' do
    policies_by_name = ['test_1' 'test_2']
    policies_by_id = ['abc-123' 'xyz-456']
    ca_file = '/tmp/ca.pem'

    before :each do
      @token = Puppet::Type.type(:consul_token).new(
        :name => 'testing',
        :accessor_id => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
        :policies_by_name => policies_by_name,
        :policies_by_id => policies_by_id,
        :ca_file => ca_file,
        )
    end

    it 'should accept a accessor id' do
      expect(@token[:accessor_id]).to eq('39c75e12-7f43-0a40-dfba-9aa3fcda08d4')
    end

    it 'should accept policy names' do
      expect(@token[:policies_by_name]).to eq(policies_by_name)
    end

    it 'should accept policy IDs' do
      expect(@token[:policies_by_id]).to eq(policies_by_id)
    end

    it 'should accept a ca_file' do
      expect(@token[:ca_file]).to eq(ca_file)
    end

    it 'should default to localhost' do
      expect(@token[:hostname]).to eq('localhost')
    end

    it 'should default to http' do
      expect(@token[:protocol]).to eq(:http)
    end

    it 'should default to port 8500' do
      expect(@token[:port]).to eq(8500)
    end
  end
end
