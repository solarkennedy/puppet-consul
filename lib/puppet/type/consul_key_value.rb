Puppet::Type.newtype(:consul_key_value) do

  desc <<-'EOD'
  Manage a consul key value object.
  EOD
  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of the key/value object'
    validate do |value|
      raise ArgumentError, "Key/value object name must be a string" if not value.is_a?(String)
    end
  end

  newparam(:flags) do
    desc 'Flags integer'
    validate do |value|
      raise ArgumentError, "The flags value must be an integer" if not value.is_a?(Integer)
    end
    defaultto 0
  end

  newproperty(:value) do
    desc 'The key value string'
    validate do |value|
      raise ArgumentError, "The key value must be a string" if not value.is_a?(String)
    end
  end

  newparam(:acl_api_token) do
    desc 'Token for accessing the ACL API'
    validate do |value|
      raise ArgumentError, "ACL API token must be a string" if not value.is_a?(String)
    end
    defaultto ''
  end

  newparam(:datacenter) do
    desc 'Name of the datacenter to query. If unspecified, the query will default to the datacenter of the Consul agent at the HTTP address.'
    validate do |value|
      raise ArgumentError, "Datacenter must be a string" if not value.is_a?(String)
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
end
