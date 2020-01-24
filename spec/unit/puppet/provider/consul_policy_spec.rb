require 'spec_helper'
require 'json'

describe Puppet::Type.type(:consul_policy).provider(:default) do
  resource_params = {
    :name          => 'test_policy',
    :description   => 'test description',
    :rules         => [
      {
        'resource'    => 'service_prefix',
        'segment'     => 'test_service',
        'disposition' => 'read'
      },
      {
        'resource'    => 'key',
        'segment'     => 'test_key',
        'disposition' => 'write'
      },
    ],
    :acl_api_token => 'e33653a6-0320-4a71-b3af-75f14578e3aa',
    :api_tries     => 3,
    :ca_file       => '/tmp/ca.pem',
    :ensure        => 'present'
  }
  let(:resource) { Puppet::Type.type(:consul_policy).new(
    resource_params
  )}

  let(:resources) { { 'test_policy' => resource } }

  describe '.list_resources' do
    context "when the first two responses are unexpected" do
      it 'should retry 3 times' do
        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 400, :body => "", :headers => {}).times(2).then.
            to_return(:status => 200, :body => '[]', :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:ensure]).to eql(:present)
      end

      it 'ID matched' do
        list_response = [
            {
                "ID"           => "02298dc3-e1cd-e031-b2c8-ec3023702b20",
                "Name"         => "test_policy",
                "Description"  => "Test description",
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        policy_response = list_response.first
        policy_response['Rules'] = []

        stub_request(:get, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(policy_response), :headers => {})

        resource[:id] = ''
        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:id]).to eql("02298dc3-e1cd-e031-b2c8-ec3023702b20")
      end
    end

    context "over HTTPS" do
      let(:resource) { Puppet::Type.type(:consul_policy).new(
        resource_params.merge({:protocol => 'https'})
      )}
      it 'should not fail' do
        stub_request(:get, "https://localhost:8500/v1/acl/policies").
          with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => '[]', :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:ensure]).to eql(:present)
      end
    end
  end

  describe 'create' do
    context "when the first two responses are unexpected" do
      it 'should retry 3 times' do
        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 400, :body => "", :headers => {}).times(2).then.
            to_return(:status => 200, :body => '[]', :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:ensure]).to eql(:present)
      end
    end

    context "matching data" do
      it 'matches ID on equal names' do
        list_response = [
            {
                "ID"           => "02298dc3-e1cd-e031-b2c8-ec3023702b20",
                "Name"         => "test_policy",
                "Description"  => "Test description",
            },
            {
                "ID"           => "92cc32cd-ef8e-4c5d-909a-e3fc625293fc",
                "Name"         => "other_policy",
                "Description"  => "Other description",
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        policy_response = list_response.first
        policy_response['Rules'] = []

        stub_request(:get, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(policy_response), :headers => {})

        resource[:id] = ''
        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:id]).to eql("02298dc3-e1cd-e031-b2c8-ec3023702b20")
      end

      it 'aborts if no policy is found by specified ID' do
        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => '[]', :headers => {})

        resource[:id] = '02298dc3-e1cd-e031-b2c8-ec3023702b20'
        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:ensure]).to eql(:absent)
      end
    end
  end

  describe 'flush' do
    context "create" do
      it 'if policy is not existing' do
        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => '[]', :headers => {})

        create_response = {
            "ID"           => "ce6c53fb-aebd-4acb-b108-b65d4ea67853",
            "Name"         => "test_policy",
            "Description"  => "Test description",
            "Rules"        => []
        }

        stub_request(:put, "http://localhost:8500/v1/acl/policy").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"Name\":\"test_policy\",\"Description\":\"test description\",\"Rules\":\"service_prefix \\\"test_service\\\" {\\n  policy = \\\"read\\\"\\n}\\n\\nkey \\\"test_key\\\" {\\n  policy = \\\"write\\\"\\n}\"}").
            to_return(:status => 200, :body => JSON.dump(create_response), :headers => {})

        resource[:id] = ''
        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
        expect(resource[:id]).to eql("ce6c53fb-aebd-4acb-b108-b65d4ea67853")
      end
    end

    context "update" do
      it 'if descriptions do not match"' do
        list_response = [
            {
                "ID"           => "02298dc3-e1cd-e031-b2c8-ec3023702b20",
                "Name"         => "test_policy",
                "Description"  => "other description",
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        policy_response = list_response.first
        policy_response['Rules'] = described_class.encode_rules(resource[:rules])

        stub_request(:get, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(policy_response), :headers => {})

        update_response = policy_response
        update_response['Description'] = "test description"

        stub_request(:put, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"Name\":\"test_policy\",\"Description\":\"test description\",\"Rules\":\"service_prefix \\\"test_service\\\" {\\n  policy = \\\"read\\\"\\n}\\n\\nkey \\\"test_key\\\" {\\n  policy = \\\"write\\\"\\n}\"}").
            to_return(:status => 200, :body => JSON.dump(update_response), :headers => {})

        resource[:id] = ''
        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
      end

      it 'if rules do not match"' do
        list_response = [
            {
                "ID"           => "02298dc3-e1cd-e031-b2c8-ec3023702b20",
                "Name"         => "test_policy",
                "Description"  => "test description",
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        policy_response = list_response.first
        policy_response['Rules'] = ""

        stub_request(:get, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(policy_response), :headers => {})

        update_response = policy_response
        update_response['Rules'] = described_class.encode_rules(resource[:rules])

        stub_request(:put, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"Name\":\"test_policy\",\"Description\":\"test description\",\"Rules\":\"service_prefix \\\"test_service\\\" {\\n  policy = \\\"read\\\"\\n}\\n\\nkey \\\"test_key\\\" {\\n  policy = \\\"write\\\"\\n}\"}").
            to_return(:status => 200, :body => JSON.dump(update_response), :headers => {})

        resource[:id] = ''
        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
      end


      it 'no update if rules and description are equal"' do
        list_response = [
            {
                "ID"           => "02298dc3-e1cd-e031-b2c8-ec3023702b20",
                "Name"         => "test_policy",
                "Description"  => "test description",
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        policy_response = list_response.first
        policy_response['Rules'] = described_class.encode_rules(resource[:rules])

        stub_request(:get, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(policy_response), :headers => {})

        resource[:id] = ''
        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
      end
    end

    context "delete" do
      it 'absent and existing policy"' do
        list_response = [
            {
                "ID"           => "02298dc3-e1cd-e031-b2c8-ec3023702b20",
                "Name"         => "test_policy",
                "Description"  => "other description",
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        policy_response = list_response.first
        policy_response['Rules'] = described_class.encode_rules(resource[:rules])

        stub_request(:get, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(policy_response), :headers => {})


        stub_request(:delete, "http://localhost:8500/v1/acl/policy/02298dc3-e1cd-e031-b2c8-ec3023702b20").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => '[]', :headers => {})

        resource[:id] = ''
        resource[:ensure] = :absent
        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
      end

      it 'absent and non-existing policy"' do
        stub_request(:get, "http://localhost:8500/v1/acl/policies").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => '[]', :headers => {})

        resource[:id] = 'd555e778-b2e0-441e-9734-f76f3e9f43ca'
        resource[:ensure] = :absent
        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
      end
    end
  end
end
