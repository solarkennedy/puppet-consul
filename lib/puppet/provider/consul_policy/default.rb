require 'json'
require 'net/http'
require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "puppet_x", "consul", "acl_base.rb"))

Puppet::Type.type(:consul_policy).provide(
    :default
) do
  mk_resource_methods

  def self.prefetch(resources)
    resources.each do |name, resource|
      rules_encoded = encode_rules(resource[:rules])

      all_policies = list_policies(resource[:acl_api_token], resource[:hostname], resource[:port], resource[:protocol], resource[:ca_file], resource[:api_tries])

      if resource[:id] == ''
        existing_policy = all_policies.select{|policy| policy.name == name}
      else
        existing_policy = all_policies.select{|policy| policy.id == resource[:id]}

        if existing_policy.empty?
          Puppet.warning("Unable to find any existing Consul ACL policy by specified ID=#{resource[:id]}")
          resource[:ensure] = :absent
          return
        end
      end

      if existing_policy.length > 0
        existing_policy = existing_policy.first
        resource[:id] = existing_policy.id

        existing_policy.rules = @client.get_policy_rules(existing_policy.id, resource[:api_tries])
      else
        existing_policy = nil
      end

      resource.provider = new({}, @client, rules_encoded, existing_policy, resource)
    end
  end

  def self.encode_rules(rules)
    encoded = []

    rules.each do |rule|
      if ['acl', 'operator'].include?(rule['resource'])
        encoded.push("#{rule['resource']} = \"#{rule['disposition']}\"")
      else
        encoded.push("#{rule['resource']} \"#{rule['segment']}\" {\n  policy = \"#{rule['disposition']}\"\n}")
      end
    end

    encoded.join("\n\n")
  end

  def self.list_policies(acl_api_token, hostname, port, protocol, ca_file, tries)
    @all_policies ||= nil
    if @all_policies
      return @all_policies
    end

    @client ||= ConsulACLPolicyClient.new(hostname, port, protocol, acl_api_token, ca_file)
    @all_policies = @client.get_all_policies(tries)
    @all_policies
  end

  def initialize(messages, client = nil, rules_encoded = '', existing_policy = nil, resource = nil)
    super(messages)
    @property_flush = {}

    @client = client
    @rules_encoded = rules_encoded
    @existing_policy = existing_policy

    if existing_policy
      @property_hash = {
          :id          => existing_policy.id,
          :description => existing_policy.description
      }

      if rules_encoded == existing_policy.rules
        @property_hash[:rules] = resource[:rules]
      end
    end
  end

  def exists?
    @existing_policy
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    if @resource[:ensure] == :absent
      if @existing_policy
        @client.delete_policy(@existing_policy.id)
        Puppet.notice("Deleted Consul ACL policy #{@existing_policy.name} (ID: #{@existing_policy.id})")
      end

      return
    end

    unless @existing_policy
      policy = ConsulPolicy.new(nil, @resource[:name], @resource[:description], @rules_encoded)
      @client.create_policy(policy, @resource[:api_tries])
      @resource[:id] = policy.id
      Puppet.notice("Created Consul ACL policy #{policy.name} with ID #{policy.id}")
    end

    if @existing_policy && (@existing_policy.description != @resource[:description] || @existing_policy.rules != @rules_encoded)
      @existing_policy.description = @resource[:description]
      @existing_policy.rules = @rules_encoded

      @client.update_policy(@existing_policy)
      Puppet.notice("Updated Consul ACL policy #{@existing_policy.name} (ID: #{@existing_policy.id})")
    end
  end

  def self.reset
    @all_policies = nil
    @client = nil
  end
end

class ConsulPolicy
  attr_reader :id, :name, :description, :rules
  attr_writer :id, :rules, :description

  def initialize(id, name, description, rules)
    @id = id
    @name = name
    @description = description
    @rules = rules
  end
end

class ConsulACLPolicyClient < PuppetX::Consul::ACLBase::BaseClient
  def get_all_policies(max_tries)
    begin
      response = get('/policies', max_tries)
    rescue StandardError => e
      Puppet.warning("Cannot retrieve ACL token list: #{e.message}")
      response = {}
    end

    collection = []
    response.each {|item|
      collection.push(ConsulPolicy.new(item['ID'], item['Name'], item['Description'], nil))
    }

    collection
  end

  def get_policy_rules(policy_id, max_tries)
    begin
      response = get('/policy/' + policy_id, max_tries)
    rescue StandardError => e
      Puppet.warning("Cannot retrieve ACL #{id}: #{e.message}")
      return ''
    end

    response['Rules']
  end

  def create_policy(policy, tries)
    body = create_body(policy)

    begin
      response = put('/policy', body, tries)
      policy.id = response['ID']
    rescue StandardError => e
      Puppet.warning("Unable to create policy #{policy.name}: #{e.message}")
    end
  end

  def update_policy(policy)
    body = create_body(policy)

    begin
      put('/policy/' + policy.id, body)
    rescue StandardError => e
      Puppet.warning("Unable to update policy #{policy.name} (ID: #{policy.id}): #{e.message}")
    end
  end

  def create_body(policy)
    body = {}
    body.store('Name', policy.name)
    body.store('Description', policy.description)
    body.store('Rules', policy.rules)

    body
  end

  def delete_policy(id)
    delete('/policy/' + id)
  end
end
