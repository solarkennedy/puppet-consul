Puppet::Type.newtype(:consul_policy) do

  desc <<-'EOD'
  Manages a Consul ACL policy
  EOD
  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of the policy'
    validate do |value|
      raise ArgumentError, "Policy name must be a string" if not value.is_a?(String)
    end
  end

  newproperty(:id) do
    desc 'ID of already existing policy'
    validate do |value|
      raise ArgumentError, "ID must be a string" if not value.is_a?(String)
    end

    defaultto ''
  end

  newproperty(:description) do
    desc 'Description of the policy'
    validate do |value|
      raise ArgumentError, "Description must be a string" if not value.is_a?(String)
    end
  end

  newproperty(:rules, :array_matching => :all) do
    desc 'List of ACL rules for this policy'
    validate do |value|
      raise ArgumentError, "Policy rule must be a hash" unless value.is_a?(Hash)

      raise ArgumentError, "Policy rule needs to specify a resource" unless value.key?('resource')
      raise ArgumentError, "Policy rule needs to specify a segment" unless value.key?('segment') || ['acl', 'operator'].include?(value['resource'])
      raise ArgumentError, "Policy rule needs to specify a disposition" unless value.key?('disposition')

      raise ArgumentError, "Policy rule resource must be a string" unless value['resource'].is_a?(String)
      raise ArgumentError, "Policy rule segment must be a string" unless value['segment'].is_a?(String) || ['acl', 'operator'].include?(value['resource'])
      raise ArgumentError, "Policy rule disposition must be a string" unless value['disposition'].is_a?(String)
    end

    defaultto []
  end

  newparam(:acl_api_token) do
    desc 'Token for accessing the ACL API'
    validate do |value|
      raise ArgumentError, "ACL API token must be a string" if not value.is_a?(String)
    end
    defaultto ''
  end

  newparam(:protocol) do
    desc 'consul protocol'
    newvalues(:http, :https)
    defaultto :http
  end

  newparam(:port) do
    desc 'consul port'
    defaultto 8500
    validate do |value|
      raise ArgumentError, "The port number must be a number" if not value.is_a?(Integer)
    end
  end

  newparam(:hostname) do
    desc 'consul hostname'
    validate do |value|
      raise ArgumentError, "The hostname must be a string" if not value.is_a?(String)
    end
    defaultto 'localhost'
  end

  newparam(:ca_file) do
    desc 'path to custom Consul CA file'
    validate do |value|
      raise ArgumentError, "The ca_file must be a string" if not value.is_a?(String)
    end
    defaultto ''
  end

  newparam(:api_tries) do
    desc 'number of tries when contacting the Consul REST API'
    defaultto 3
    validate do |value|
      raise ArgumentError, "Number of API tries must be a number" if not value.is_a?(Integer)
    end
  end

  autorequire(:service) do
    ['consul']
  end
end
