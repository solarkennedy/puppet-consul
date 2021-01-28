Puppet::Functions.create_function(:'consul::validate_checks') do

  local_types do
    type 'HashOrArray = Variant[Hash,Array]'
  end

  dispatch :validate_checks do
    param 'HashOrArray', :obj
  end

  def validate_checks(obj)
    case obj
        when Array
        obj.each do |c|
            validate_checks(c)
        end
        when Hash
            is_http = obj.key?("http")
            is_tcp = obj.key?("tcp")
            is_grpc = obj.key?("grpc")
            is_script = obj.key?("script") || obj.key?("args")
            is_ttl = obj.key?("ttl")
            has_interval = obj.key?("interval")

            check_types_defined = [is_http, is_tcp, is_grpc, is_script, is_ttl].count(true)

            if check_types_defined > 1
                raise Puppet::ParseError.new('multiple check types cannot be specified in a single check definition')
            elsif check_types_defined == 0
                puts obj
                raise Puppet::ParseError.new('one of the following check types must be defined: http, tcp, grpc, script, or ttl')
            end

            if (!is_ttl && !has_interval)
                raise Puppet::ParseError.new('interval must be defined for tcp, http, grpc, and script checks')
            end

            if (is_ttl && has_interval)
                raise Puppet::ParseError.new('interval must not be defined for ttl checks')
            end
        else
        raise Puppet::ParseError.new("Unable to handle object of type <%s>" % obj.class.to_s)
    end
  end
end
