require 'spec_helper'
require 'json'

describe Puppet::Type.type(:consul_token).provider(:default) do
  resource_params = {
    :name              => 'test_token',
    :accessor_id       => '123123-1234-1234-1234-123456789',
    :acl_api_token     => 'e33653a6-0320-4a71-b3af-75f14578e3aa',
    :policies_by_name  => [
      'test_policy_1'
    ],
    :policies_by_id    => [
      '652f27c9-d08d-412b-8985-9becc9c42fb2'
    ],
    :api_tries     => 3,
    :ca_file       => '/tmp/ca.pem',
    :ensure        => 'present'
  }
  let(:resource) { Puppet::Type.type(:consul_token).new(
    resource_params
  )}

  let(:resources) { { 'test_token' => resource } }

  describe '.list_resources' do
    context "when the first two responses are unexpected" do
      it 'should retry 3 times' do
        response = [
            {
                'AccessorID'  => '803ba11a-afe9-4198-a179-ef25a2adbf0b',
                'Description' => 'Test description',
                'Policies'    => []
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 400, :body => "", :headers => {}).times(2).then.
            to_return(:status => 200, :body => JSON.dump(response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:ensure]).to eql(:present)
      end
    end

    context "when matching existing tokens" do
      it 'should set accessor' do
        response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'Description' => 'test_token',
                'Policies'    => []
            },
            {
                'AccessorID'  => '54636c2c-f378-428d-8b74-ac72cc6dd32d',
                'Description' => 'other token',
                'Policies'    => []
            }
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:accessor_id]).to eql('123123-1234-1234-1234-123456789')
      end
    end

    context "over HTTPS" do
      let(:resource) { Puppet::Type.type(:consul_token).new(
        resource_params.merge({:protocol => 'https'})
      )}
      response = [
          {
              'AccessorID'  => '803ba11a-afe9-4198-a179-ef25a2adbf0b',
              'Description' => 'Test description',
              'Policies'    => []
          }
      ]

      it 'should not fail' do
        response = [
            {
                'AccessorID'  => '803ba11a-afe9-4198-a179-ef25a2adbf0b',
                'Description' => 'Test description',
                'Policies'    => []
            }
        ]

        stub_request(:get, "https://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        expect(resource[:ensure]).to eql(:present)
      end
    end
  end

  describe '.flush' do
    context "creation" do
      it 'should create token if not existing' do
        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump([]), :headers => {})

        response = {
            'AccessorID'  => 'f28febb0-8746-4b6a-b6bf-03cde92005a1',
            'SecretID'    => '11cfc2b9-a823-495d-8d6e-4392f182670e',
            'Description' => 'test_token',
            'Policies'    => []
        }

        create_response_stub = stub_request(:put, "http://localhost:8500/v1/acl/token").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"AccessorID\":\"123123-1234-1234-1234-123456789\",\"Description\":\"test_token\",\"Local\":false,\"Policies\":[{\"Name\":\"test_policy_1\"},{\"ID\":\"652f27c9-d08d-412b-8985-9becc9c42fb2\"}]}").
            to_return(:status => 200, :body => JSON.dump(response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush

        expect(resource[:accessor_id]).to eql('f28febb0-8746-4b6a-b6bf-03cde92005a1')
        assert_requested(create_response_stub)
      end
    end

    context "secret_id creation" do
      let(:resource) { Puppet::Type.type(:consul_token).new(
          {
              :name              => 'test_token',
              :accessor_id       => '123123-1234-1234-1234-123456789',
              :secret_id          => '11cfc2b9-a823-495d-8d6e-4392f182670e',
              :acl_api_token     => 'e33653a6-0320-4a71-b3af-75f14578e3aa',
              :policies_by_name  => [
                  'test_policy_1'
              ],
              :policies_by_id    => [
                  '652f27c9-d08d-412b-8985-9becc9c42fb2'
              ],
              :api_tries     => 3,
              :ensure        => 'present'
          }
      )}

      it 'should set secret_id if present' do
        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump([]), :headers => {})

        response = {
            'AccessorID'  => 'f28febb0-8746-4b6a-b6bf-03cde92005a1',
            'SecretID'    => '11cfc2b9-a823-495d-8d6e-4392f182670e',
            'Description' => 'test_token',
            'Policies'    => []
        }

        create_response_stub = stub_request(:put, "http://localhost:8500/v1/acl/token").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"AccessorID\":\"123123-1234-1234-1234-123456789\",\"Description\":\"test_token\",\"Local\":false,\"Policies\":[{\"Name\":\"test_policy_1\"},{\"ID\":\"652f27c9-d08d-412b-8985-9becc9c42fb2\"}],\"SecretID\":\"11cfc2b9-a823-495d-8d6e-4392f182670e\"}").
            to_return(:status => 200, :body => JSON.dump(response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush

        expect(resource[:accessor_id]).to eql('f28febb0-8746-4b6a-b6bf-03cde92005a1')
        assert_requested(create_response_stub)
      end
    end

    context "update" do
      it 'should update policies in case of missing policy ID' do
        list_response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
                'Description' => 'test_token',
                'Policies'    => [
                    {
                        'ID'   => '91c889b8-88fe-46d0-bdbd-54447fcd191b',
                        'Name' => 'test_policy_1'
                    }
                ]
            },
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        update_response = {
            'AccessorID'  => '123123-1234-1234-1234-123456789',
            'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
            'Description' => 'test_token',
            'Policies'    => []
        }

        update_response_stub = stub_request(:put, "http://localhost:8500/v1/acl/token/123123-1234-1234-1234-123456789").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"AccessorID\":\"123123-1234-1234-1234-123456789\",\"Description\":\"test_token\",\"Local\":false,\"Policies\":[{\"Name\":\"test_policy_1\"},{\"ID\":\"652f27c9-d08d-412b-8985-9becc9c42fb2\"}]}").
            to_return(:status => 200, :body => JSON.dump(update_response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush

        assert_requested(update_response_stub)
      end

      it 'should update policies in case of missing policy Name' do
        list_response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
                'Description' => 'test_token',
                'Policies'    => [
                    {
                        'ID'   => '652f27c9-d08d-412b-8985-9becc9c42fb2',
                        'Name' => 'test_policy_2'
                    }
                ]
            },
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        update_response = {
            'AccessorID'  => '123123-1234-1234-1234-123456789',
            'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
            'Description' => 'test_token',
            'Policies'    => []
        }

        update_response_stub = stub_request(:put, "http://localhost:8500/v1/acl/token/123123-1234-1234-1234-123456789").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"AccessorID\":\"123123-1234-1234-1234-123456789\",\"Description\":\"test_token\",\"Local\":false,\"Policies\":[{\"Name\":\"test_policy_1\"},{\"ID\":\"652f27c9-d08d-412b-8985-9becc9c42fb2\"}]}").
            to_return(:status => 200, :body => JSON.dump(update_response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush

        assert_requested(update_response_stub)
      end

      it 'should update policies in case of surplus policy' do
        list_response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
                'Description' => 'test_token',
                'Policies'    => [
                    {
                        'ID'   => '91c889b8-88fe-46d0-bdbd-54447fcd191b',
                        'Name' => 'test_policy_1'
                    },
                    {
                        'ID'   => '652f27c9-d08d-412b-8985-9becc9c42fb2',
                        'Name' => 'test_policy_2'
                    },
                    {
                        'ID'   => 'a213e6b6-a7d9-484a-9223-94dfb96cc99f',
                        'Name' => 'surplus_policy'
                    },
                ]
            },
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        update_response = {
            'AccessorID'  => '123123-1234-1234-1234-123456789',
            'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
            'Description' => 'test_token',
            'Policies'    => []
        }

        update_response_stub = stub_request(:put, "http://localhost:8500/v1/acl/token/123123-1234-1234-1234-123456789").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"AccessorID\":\"123123-1234-1234-1234-123456789\",\"Description\":\"test_token\",\"Local\":false,\"Policies\":[{\"Name\":\"test_policy_1\"},{\"ID\":\"652f27c9-d08d-412b-8985-9becc9c42fb2\"}]}").
            to_return(:status => 200, :body => JSON.dump(update_response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush

        assert_requested(update_response_stub)
      end

      it 'should update policies in case of other policy_name' do
        list_response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
                'Description' => 'test_token',
                'Policies'    => [
                    {
                        'ID'   => '91c889b8-88fe-46d0-bdbd-54447fcd191b',
                        'Name' => 'other_name'
                    },
                    {
                        'ID'   => '652f27c9-d08d-412b-8985-9becc9c42fb2',
                        'Name' => 'test_policy_2'
                    }
                ]
            },
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        update_response = {
            'AccessorID'  => '123123-1234-1234-1234-123456789',
            'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
            'Description' => 'test_token',
            'Policies'    => []
        }

        update_response_stub = stub_request(:put, "http://localhost:8500/v1/acl/token/123123-1234-1234-1234-123456789").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'},
                 :body    => "{\"AccessorID\":\"123123-1234-1234-1234-123456789\",\"Description\":\"test_token\",\"Local\":false,\"Policies\":[{\"Name\":\"test_policy_1\"},{\"ID\":\"652f27c9-d08d-412b-8985-9becc9c42fb2\"}]}").
            to_return(:status => 200, :body => JSON.dump(update_response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush

        assert_requested(update_response_stub)
      end

      it 'no update if policies match' do
        list_response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
                'Description' => 'test_token',
                'Policies'    => [
                    {
                        'ID'   => '91c889b8-88fe-46d0-bdbd-54447fcd191b',
                        'Name' => 'test_policy_1'
                    },
                    {
                        'ID'   => '652f27c9-d08d-412b-8985-9becc9c42fb2',
                        'Name' => 'test_policy_2'
                    }
                ]
            },
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource.provider.create
        resource.provider.flush
      end
    end

    context "delete" do
      it 'should delete absent existing token' do
        list_response = [
            {
                'AccessorID'  => '123123-1234-1234-1234-123456789',
                'SecretID'    => 'ebc71d90-7a30-4f83-b108-6c5d9bda3225',
                'Description' => 'test_token',
                'Policies'    => []
            },
        ]

        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => JSON.dump(list_response), :headers => {})

        delete_response_stub = stub_request(:delete, "http://localhost:8500/v1/acl/token/123123-1234-1234-1234-123456789").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => '[]', :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource[:ensure] = :absent
        resource.provider.destroy
        resource.provider.flush

        assert_requested(delete_response_stub)
      end

      it 'should not delete absent non-existing token' do
        stub_request(:get, "http://localhost:8500/v1/acl/tokens").
            with(:headers => {'X-Consul-Token'=> 'e33653a6-0320-4a71-b3af-75f14578e3aa', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => '[]', :headers => {})

        described_class.prefetch(resources)
        described_class.reset
        resource[:ensure] = :absent
        resource.provider.destroy
        resource.provider.flush
      end
    end
  end
end
