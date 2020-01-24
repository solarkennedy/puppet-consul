require 'json'
require 'net/http'
require 'uri'
require 'base64'
require 'openssl'
Puppet::Type.type(:consul_key_value).provide(
  :default
) do
  mk_resource_methods

  def self.prefetch(resources)
    resources.each do |name, resource|
      Puppet.debug("prefetching for #{name}")
      port = resource[:port]
      hostname = resource[:hostname]
      protocol = resource[:protocol]
      token = resource[:acl_api_token]
      tries = resource[:api_tries]
      datacenter = resource[:datacenter]

      found_key_values = list_resources(token, port, hostname, protocol, tries, datacenter).select do |key_value|
        key_value[:name] == name
      end

      found_key_value = found_key_values.first || nil
      if found_key_value
        Puppet.debug("found #{found_key_value}")
        resource.provider = new(found_key_value)
      else
        Puppet.debug("found none #{name}")
        resource.provider = new({:ensure => :absent})
      end
    end
  end

  def self.list_resources(acl_api_token, port, hostname, protocol, tries, datacenter)
    @key_values ||= {}
    if @key_values[ "#{acl_api_token}#{port}#{hostname}#{protocol}#{tries}#{datacenter}" ]
      return @key_values[ "#{acl_api_token}#{port}#{hostname}#{protocol}#{tries}#{datacenter}" ]
    end

    # this might be configurable by searching /etc/consul.d
    # but would break for anyone using nonstandard paths
    consul_url = "#{protocol}://#{hostname}:#{port}/v1/kv/?dc=#{datacenter}&recurse&token=#{acl_api_token}"

    uri = URI(consul_url)
    res = nil

    # retry Consul API query for ACLs, in case Consul has just started
    (1..tries).each do |i|
      unless i == 1
        Puppet.debug("retrying Consul API query in #{i} seconds")
        sleep i
      end
      res = Net::HTTP.get_response(uri)
      break if res.code == '200'
    end

    if res.code == '200'
      key_values = JSON.parse(res.body)

    # No keys exists yet in this datacenter
    elsif res.code == '404'
      return []
    else
      Puppet.warning("Cannot retrieve key_values: invalid return code #{res.code} uri: #{uri.request_uri}")
      return {}
    end

    nkey_values = key_values.collect do |key_value|
      {
        :name     => key_value["Key"],
        :value    => (key_value["Value"] == nil ? '' : Base64.decode64(key_value["Value"])),
        :flags    => Integer(key_value["Flags"]),
        :ensure   => :present,
        :protocol => protocol,
      }
    end
    @key_values[ "#{acl_api_token}#{port}#{hostname}#{protocol}#{tries}#{datacenter}" ] = nkey_values
    nkey_values
  end

  # Reset the state of the provider between tests.
  def self.reset()
    @key_values = {}
  end

  def get_path(name)
    uri = URI("#{@resource[:protocol]}://#{@resource[:hostname]}:#{@resource[:port]}/v1/kv/#{name}?dc=#{@resource[:datacenter]}&token=#{@resource[:acl_api_token]}")
    http = Net::HTTP.new(uri.host, uri.port)
    acl_api_token = @resource[:acl_api_token]
    ca_file = @resource[:ca_file]

    if uri.scheme == 'https'
      Puppet.debug("Protocol #{@global_uri.scheme}, turning on Net::HTTP SSL")
      http.use_ssl = true
    end

    if ca_file != nil and ca_file != ''
      Puppet.debug("Custom CA file #{ca_file} specified")
      if File.file?(ca_file)
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        store.add_file(ca_file)
        http.cert_store = store
      else
        Puppet.warning("CA File #{ca_file} doesn't exist")
      end
    end

    return uri.request_uri, http
  end

  def create_or_update_key_value(name, value, flags)
    path, http = get_path(name)
    req = Net::HTTP::Put.new(path + "&flags=#{flags}")
    req.body = value
    res = http.request(req)
    if res.code != '200'
      raise(Puppet::Error,"Session #{name} create/update: invalid return code #{res.code} uri: #{path} body: #{req.body}")
    end
  end

  def delete_key_value(name)
    path, http = get_path(name)
    req = Net::HTTP::Delete.new(path)
    res = http.request(req)
    if res.code != '200'
      raise(Puppet::Error,"Session #{name} delete: invalid return code #{res.code} uri: #{path} body: #{req.body}")
    end
  end

  def get_resource(name, port, hostname, protocol, tries, datacenter)
    acl_api_token = @resource[:acl_api_token]
    resources = self.class.list_resources(acl_api_token, port, hostname, protocol, tries, datacenter).select do |res|
      res[:name] == name
    end
    # if the user creates multiple with the same name this will do odd things
    resources.first || nil
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    # flush is only called when something really needs to change.
    # a property has a different value or maybe the resource needs to be created or destroyed.
    # http://garylarizza.com/blog/2013/12/15/seriously-what-is-this-provider-doing/

    name = @resource[:name]
    flags = @resource[:flags]
    value = @resource[:value]
    port = @resource[:port]
    hostname = @resource[:hostname]
    protocol = @resource[:protocol]
    tries = @resource[:api_tries]
    datacenter = @resource[:datacenter]
    key_value = self.get_resource(name, port, hostname, protocol, tries, datacenter)

    if @property_flush[:ensure] == :absent
      #key exists in the kv, but must be deleted.
      delete_key_value(name)
    else
      #something changed, otherwise the flush method would not have been called.
      create_or_update_key_value(name, value, flags)
    end
    @property_hash.clear
  end
end
