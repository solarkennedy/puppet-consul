require 'spec_helper'

describe Puppet::Type.type(:consul_policy) do

  it 'should fail if no name is provided' do
    expect do
      Puppet::Type.type(:consul_policy).new(:id => {}, :rules => {})
    end.to raise_error(Puppet::Error, /Title or name must be provided/)
  end

  it 'should fail if ID ist not a string' do
    expect do
      Puppet::Type.type(:consul_policy).new(:name => 'foo', :id => {})
    end.to raise_error(Puppet::Error, /ID must be a string/)
  end

  it 'should fail if description ist not a string' do
    expect do
      Puppet::Type.type(:consul_policy).new(:name => 'foo', :description => {})
    end.to raise_error(Puppet::Error, /Description must be a string/)
  end

  it 'should fail if rules is not a hash' do
    expect do
      Puppet::Type.type(:consul_policy).new(
          :name         => 'testing',
          :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
          :description  => 'test description',
          :rules        => 'abc'
      )
    end.to raise_error(Puppet::Error, /Policy rule must be a hash/)
  end

  it 'should fail if rule resource is missing' do
    expect do
      Puppet::Type.type(:consul_policy).new(
          :name         => 'testing',
          :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
          :description  => 'test description',
          :rules        => [
              {
                  'segment'     => 'test_service',
                  'disposition' => 'read'
              }
          ]
      )
    end.to raise_error(Puppet::Error, /Policy rule needs to specify a resource/)
  end

  it 'should fail if rule disposition is missing' do
    expect do
      Puppet::Type.type(:consul_policy).new(
          :name         => 'testing',
          :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
          :description  => 'test description',
          :rules        => [
              {
                  'resource'    =>  'service_prefix',
                  'segment'     => 'test_service',
              }
          ]
      )
    end.to raise_error(Puppet::Error, /Policy rule needs to specify a disposition/)
  end

  it 'should fail if rule resource is not a string' do
    expect do
      Puppet::Type.type(:consul_policy).new(
          :name         => 'testing',
          :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
          :description  => 'test description',
          :rules        => [
              {
                  'resource'    => [],
                  'segment'     => 'test_service',
                  'disposition' => 'read'
              }
          ]
      )
    end.to raise_error(Puppet::Error, /Policy rule resource must be a string/)
  end

  it 'should fail if rule disposition is not a string' do
    expect do
      Puppet::Type.type(:consul_policy).new(
          :name         => 'testing',
          :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
          :description  => 'test description',
          :rules        => [
              {
                  'resource'    => 'key_prefix',
                  'segment'     => 'test_service',
                  'disposition' => []
              }
          ]
      )
    end.to raise_error(Puppet::Error, /Policy rule disposition must be a string/)
  end

  context 'resource is acl or operator' do
    it 'should pass if rule segment is missing' do
      expect do
        Puppet::Type.type(:consul_policy).new(
            :name         => 'testing',
            :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
            :description  => 'test description',
            :rules        => [
                {
                    'resource'    => 'acl',
                    'disposition' => 'read'
                }
            ]
        )
        Puppet::Type.type(:consul_policy).new(
          :name         => 'testing',
          :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
          :description  => 'test description',
          :rules        => [
              {
                  'resource'    => 'operator',
                  'disposition' => 'read'
              }
          ]
        )
      end.not_to raise_error
    end

    it 'should pass if rule segment is not a string' do
      expect do
        Puppet::Type.type(:consul_policy).new(
            :name         => 'testing',
            :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
            :description  => 'test description',
            :rules        => [
                {
                    'resource'    => 'operator',
                    'segment'     => [],
                    'disposition' => 'read'
                }
            ]
        )
      end.not_to raise_error
    end
  end

  context 'resource is neither acl nor operator' do
    it 'should fail if rule segment is missing' do
      expect do
        Puppet::Type.type(:consul_policy).new(
            :name         => 'testing',
            :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
            :description  => 'test description',
            :rules        => [
                {
                    'resource'    => 'service_prefix',
                    'disposition' => 'read'
                }
            ]
        )
      end.to raise_error(Puppet::Error, /Policy rule needs to specify a segment/)
    end

    it 'should fail if rule segment is not a string' do
      expect do
        Puppet::Type.type(:consul_policy).new(
            :name         => 'testing',
            :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
            :description  => 'test description',
            :rules        => [
                {
                    'resource'    => 'key_prefix',
                    'segment'     => [],
                    'disposition' => 'read'
                }
            ]
        )
      end.to raise_error(Puppet::Error, /Policy rule segment must be a string/)
    end
  end

  context 'with name defined' do
    rules = [
        {
            'resource'    =>  'service_prefix',
            'segment'     => 'test_service',
            'disposition' => 'read'
        },
        {
            'resource'    =>  'key_prefix',
            'segment'     => 'key',
            'disposition' => 'write'
        }
    ]
    ca_file = '/tmp.ca.pem'

    before :each do
      @policy = Puppet::Type.type(:consul_policy).new(
        :name         => 'testing',
        :id           => '39c75e12-7f43-0a40-dfba-9aa3fcda08d4',
        :description  => 'test description',
        :rules        => rules,
        :ca_file      => ca_file
      )
    end

    it 'should accept an id' do
      expect(@policy[:id]).to eq('39c75e12-7f43-0a40-dfba-9aa3fcda08d4')
    end

    it 'should accept a description' do
      expect(@policy[:description]).to eq('test description')
    end

    it 'should accept rules' do
      expect(@policy[:rules]).to eq(rules)
    end

    it 'should accept a ca_file' do
      expect(@policy[:ca_file]).to eq(ca_file)
    end

    it 'should default to localhost' do
      expect(@policy[:hostname]).to eq('localhost')
    end

    it 'should default to http' do
      expect(@policy[:protocol]).to eq(:http)
    end

    it 'should default to port 8500' do
      expect(@policy[:port]).to eq(8500)
    end
  end
end
