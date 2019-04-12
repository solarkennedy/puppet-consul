require 'puppet_x'
require 'json'
require 'net/http'
require 'uri'

module PuppetX::Consul
    module PuppetX::Consul::ACLBase

      class BaseClient
        def initialize (hostname, port, protocol, api_token = nil)
          @global_uri = URI("#{protocol}://#{hostname}:#{port}/v1/acl")
          @http_client = Net::HTTP.new(@global_uri.host, @global_uri.port)
          @api_token = api_token
        end

        def get (path, tries = 1)
          path = @global_uri.request_uri + path
          request = Net::HTTP::Get.new(path)

          send_request(request, tries)
        end

        def put (path, body)
          path = @global_uri.request_uri + path
          request = Net::HTTP::Put.new(path)
          request.body = body.to_json

          send_request(request, 1)
        end

        def delete (path)
          path = @global_uri.request_uri + path
          request = Net::HTTP::Delete.new(path)

          send_request(request, 1, false )
        end

        def send_request(request, tries = 1, json_response=true)
          response_code = nil
          response = nil

          if @api_token != nil
            request['X-Consul-Token'] = @api_token
          end

          (1..tries).each do |i|
            unless i == 1
              Puppet.debug("retrying Consul API query in #{i} seconds")
              sleep i
            end

            begin
              response = @http_client.request(request)
              response_code = response.code
              break if response_code == '200'
            rescue Errno::ECONNREFUSED => exc
              Puppet.debug("#{uri}/list?token=<redacted> #{exc.class} #{exc.message}")
            end
          end

          if response_code == '200'
            json_response ? JSON.parse(response.body) : response.body
          elsif response_code != nil
            raise "Got negative API response (Code: #{response_code}, Response: #{response.body})"
          else
            raise "Connection refused by API after #{tries} tries"
          end
        end
      end

    end
end