require 'puppet/parameter/boolean'

Puppet::Type.newtype(:consul_prepared_query) do

  desc <<-'EOD'
  Manage a consul prepared query.
  EOD
  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of the prepared query'
    validate do |value|
      raise ArgumentError, "Prepared query name must be a string" if not value.is_a?(String)
    end
  end

  newparam(:token) do
    desc 'The prepared query token'
    validate do |value|
      raise ArgumentError, "The prepared query token must be a string" if not value.is_a?(String)
    end
    defaultto ''
  end

  newparam(:acl_api_token) do
    desc 'Token for accessing the ACL API'
    validate do |value|
      raise ArgumentError, "ACL API token must be a string" if not value.is_a?(String)
    end
    defaultto ''
  end

  newparam(:service_name) do
    desc 'Service name for the prepared query'
    validate do |value|
      raise ArgumentError, "Prepared query service definition must be a string" if not value.is_a?(String)
    end
  end

  newparam(:service_failover_n) do
    desc 'Failover to the nearest <n> datacenters'
    defaultto 0
    validate do |value|
      raise ArgumentError, "Nearest <n> failover datacenters must be an integer" if not value.is_a?(Integer)
    end
  end

  newparam(:service_failover_dcs) do
    desc 'List of datacenters to forward queries to if no health services found locally'
    defaultto []
    validate do |value|
      raise ArgumentError, "Nearest failover datacenters must be an array" if not value.is_a?(Array)
    end
  end

  newparam(:service_near) do
    desc 'Resurn results in ascending order of estimated RTT from given node name, or _agent special value'
    defaultto ''
    validate do |value|
      raise ArgumentError, "Near parameter must be a string" if not value.is_a?(String)
    end
  end

  newparam(:service_only_passing) do
    desc 'Only return services in the passing state'
    defaultto false
    validate do |value|
      raise ArgumentError, "Use only passing state must be a boolean" if not !!value == value
    end
  end

  newparam(:service_tags) do
    desc 'List of tags to filter the query with'
    defaultto []
    validate do |value|
      raise ArgumentError, "Query tag filters must be an array" if not value.is_a?(Array)
    end
  end

  newparam(:ttl) do
    desc 'TTL for the DNS lookup'
    defaultto 0
    validate do |value|
      raise ArgumentError, "Prepared query TTL must be an integer" if not value.is_a?(Integer)
    end
  end

  newproperty(:id) do
    desc 'ID of prepared query'
  end

  newparam(:protocol) do
    desc 'consul protocol'
    newvalues('http', 'https')
    defaultto 'http'
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

  newparam(:template, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'is template?'
    defaultto false
  end

  newparam(:template_regexp) do
    desc 'regexp for template'
    defaultto ''
    validate do |value|
      raise ArgumentError, "The template regexp must be a string" if not value.is_a?(String)
    end
  end

  newparam(:template_type) do
    desc 'type for template'
    defaultto 'name_prefix_match'
    validate do |value|
      raise ArgumentError, "The template type must be a string" if not value.is_a?(String)
    end
  end
end
