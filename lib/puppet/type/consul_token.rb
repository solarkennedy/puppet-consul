Puppet::Type.newtype(:consul_token) do

  desc <<-'EOD'
  Manages a v2 Consul token
  EOD
  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of the token'
    validate do |value|
      raise ArgumentError, "Token name must be a string" if not value.is_a?(String)
    end
  end

  newproperty(:accessor_id) do
    desc 'Accessor ID of the token'
    validate do |value|
      raise ArgumentError, "Accessor ID must be a string" if not value.is_a?(String)
    end
  end

  newproperty(:secret_id) do
    desc 'Secret ID of the token'
    validate do |value|
      raise ArgumentError, "Secret ID must be a string" if not value.is_a?(String)
    end

    defaultto ''
  end

  newproperty(:policies_by_name, :array_matching => :all) do
    desc 'List of policy names assigned to the token'
    validate do |value|
      raise ArgumentError, "Policy name list must be an array of strings" if not value.is_a?(String)
    end

    defaultto []
  end

  newproperty(:policies_by_id, :array_matching => :all) do
    desc 'List of policy IDs assigned to the token'
    validate do |value|
      raise ArgumentError, "Policy ID list must be an array of strings" if not value.is_a?(String)
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
