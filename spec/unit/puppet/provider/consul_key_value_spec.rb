require 'spec_helper'
require 'json'

describe Puppet::Type.type(:consul_key_value).provider(:default) do
  resource_params = {
      :name          => "sample/key",
      :value         => 'sampleValue',
      :acl_api_token => 'sampleToken',
      :datacenter    => 'dc1',
    }
  let(:resource) { Puppet::Type.type(:consul_key_value).new(
    resource_params
  )}

  let(:resources) { { 'sample/key' => resource } }

  describe '.list_resources' do
    context "when the first two responses are unexpected" do
      it 'should retry 3 times' do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/key",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 400, :body => "", :headers => {}).times(2).then.
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        expect(resource.provider.ensure).to eql(:present)
      end
    end

    context "over HTTPS" do
      let(:resource) { Puppet::Type.type(:consul_key_value).new(
        resource_params.merge({:protocol => 'https'})
      )}
      it 'should not fail' do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/key",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "https://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        expect(resource.provider.ensure).to eql(:present)
      end
    end

    context "when the first three responses are unexpected" do
      it 'should silently fail to prefetch' do
        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 400, :body => "", :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        expect(resource.provider.ensure).to eql(:absent)
      end
    end

    context "when a timeout is received" do
      it 'should not handle the timeout' do
        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_timeout

        described_class.reset
        # expect(described_class.prefetch( resources )).to raise_error
        expect{ described_class.prefetch (resources) }.to raise_error(Timeout::Error, "execution expired")
      end
    end

    context "when resources use different datacenters" do
      it 'should handle fetching properly' do
        #dc1 allready contains a key-value
        #dc2 has an empty key-value store.
        #
        #That means the providers should reflect this, unless the caching is corrupt.

        res_dc1 = Puppet::Type.type(:consul_key_value).new(
          {
            :name          => "sample/keydc1",
            :value         => 'sampleValue',
            :acl_api_token => 'sampleToken',
            :datacenter    => 'dc1',
          }
        )

        res_dc2 = Puppet::Type.type(:consul_key_value).new(
          {
            :name          => "sample/keydc2",
            :value         => 'sampleValue',
            :acl_api_token => 'sampleToken',
            :datacenter    => 'dc2',
          }
        )

        resources = { 'sample/keydc1' => res_dc1, 'sample/keydc2' => res_dc2 }

        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/keydc1",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc2&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 404, :body => "", :headers => {})

        described_class.reset
        described_class.prefetch(resources)
        expect(res_dc1.provider.exists?).to eql(true)
        expect(res_dc2.provider.exists?).to eql(false)
      end
    end
  end

  describe '#exists?' do
    context "when resource does not exists" do
      it 'should return false' do
        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 404, :body => "", :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        expect(resource.provider.exists?).to eql(false)
      end
    end

    context "when resource exists" do
      it 'it should return true' do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/key",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        expect(resource.provider.exists?).to eql(true)
      end
    end
  end


  describe '#create' do
    context "when key does not exist" do
      it "should write to consul" do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/key-different-key",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:put, "http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=0&token=sampleToken").
          with(:body => "sampleValue",
              :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

          described_class.reset
          described_class.prefetch( resources )
          resource.provider.create
          resource.provider.flush
      end
    end

    context "when key does exist, with different value" do
      it "it should write to consul" do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/key",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:put, "http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=0&token=sampleToken").
          with(:body => "sampleValue",
              :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

          described_class.reset
          described_class.prefetch( resources )
          resource.provider.create
          resource.provider.flush
      end
    end

    context "when key does exist, with different flag" do
      it "it should write to consul" do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/key",
          "Flags" => 1,
          "Value" => "c2FtcGxlVmFsdWU=", #sampleValue
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        resource = Puppet::Type.type(:consul_key_value).new(
          {
            :name          => "sample/key",
            :value         => 'sampleValue',
            :flags         => 2,
            :acl_api_token => 'sampleToken',
            :datacenter    => 'dc1',
          }
        )
        resources = { 'sample/key' => resource }

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:put, "http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=2&token=sampleToken").
          with(:body => "sampleValue",
              :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

          described_class.reset
          described_class.prefetch( resources )
          resource.provider.create
          resource.provider.flush
      end
    end

    context "when consul returns an error" do
      it "should raise Puppet::Error on failed create" do
        kv_content = [
          {"LockIndex" => 0,
          "Key" => "sample/different-key",
          "Flags" => 0,
          "Value" => "c2FtcGxlVmFsdWU=", #sampleValue
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:put, "http://localhost:8500/v1/kv/sample/key?dc=dc1&flags=0&token=sampleToken").
          with(:body => "sampleValue",
              :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 400, :body => "", :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        resource.provider.create
        expect { resource.provider.flush }.to raise_error(Puppet::Error, /Session sample\/key create\/update: invalid return code 400 uri:/)
      end
    end
  end

  describe '#destroy' do
    context "when key exists" do
      it 'should delete key' do
        kv_content = [
          {"LockIndex" => 0,
            "Key" => "sample/key",
            "Flags" => 0,
            "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
            "CreateIndex" => 1350503,
            "ModifyIndex" => 1350503}
          ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:delete, "http://localhost:8500/v1/kv/sample/key?dc=dc1&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        resource.provider.destroy
        resource.provider.flush
      end
    end

    context "when key exists, but consul returns an error" do
      it 'should raise error on failed delete' do
        kv_content = [
        {"LockIndex" => 0,
          "Key" => "sample/key",
          "Flags" => 0,
          "Value" => "RGlmZmVyZW50IHZhbHVl", #Different value
          "CreateIndex" => 1350503,
          "ModifyIndex" => 1350503}
        ]

        stub_request(:get, "http://localhost:8500/v1/kv/?dc=dc1&recurse&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => JSON.dump(kv_content), :headers => {})

        stub_request(:delete, "http://localhost:8500/v1/kv/sample/key?dc=dc1&token=sampleToken").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 400, :body => "", :headers => {})

        described_class.reset
        described_class.prefetch( resources )
        resource.provider.destroy

        expect { resource.provider.flush }.to raise_error(Puppet::Error, /Session sample\/key delete: invalid return code 400 uri:/)
      end
    end
  end
end
