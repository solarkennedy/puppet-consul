require 'spec_helper'

describe 'consul::check' do
  on_supported_os.each do |os, facts|
    next unless facts[:kernel] == 'Linux'
    context "on #{os} " do
      let :facts do
        facts
      end
  
      let(:title) { "my_check" }

      describe 'with no args' do
        let(:params) {{}}

        it {
          expect {
            should raise_error(Puppet::Error, /Wrong number of arguments/)
          }
        }
      end
      describe 'with script' do
        let(:params) {{
          'interval'    => '30s',
          'script' => 'true'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"script" *: *"true"/)
        }
      end
      describe 'with args' do
        let(:params) {{
          'interval' => '30s',
          'args'     => ['sh', '-c', 'true'],
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"args" *: *\[ *"sh", *"-c", *"true" *\]/)
        }
      end
      describe 'with script and service_id' do
        let(:params) {{
          'interval'    => '30s',
          'script' => 'true',
          'service_id' => 'my_service'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"script" *: *"true"/) \
            .with_content(/"service_id" *: *"my_service"/)
        }
      end
      describe 'reload service with script and token' do
        let(:params) {{
          'interval' => '30s',
          'script'   => 'true',
          'token'    => 'too-cool-for-this-script'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"script" *: *"true"/) \
            .with_content(/"token" *: *"too-cool-for-this-script"/) \
            .that_notifies("Class[consul::reload_service]") \
        }
      end
      describe 'with http' do
        let(:params) {{
          'interval'    => '30s',
          'http' => 'localhost'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"http" *: *"localhost"/) \
        }
      end
      describe 'with http and service_id' do
        let(:params) {{
          'interval'    => '30s',
          'http' => 'localhost',
          'service_id' => 'my_service'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"http" *: *"localhost"/) \
            .with_content(/"service_id" *: *"my_service"/)
        }
      end
      describe 'reload service with http and token' do
        let(:params) {{
          'interval' => '30s',
          'http'     => 'localhost',
          'token'    => 'too-cool-for-this-http'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"http" *: *"localhost"/) \
            .with_content(/"token" *: *"too-cool-for-this-http"/) \
            .that_notifies("Class[consul::reload_service]") \
        }
      end
      describe 'with http and removed undef values' do
        let(:params) {{
          'interval'    => '30s',
          'http' => 'localhost'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .without_content(/"service_id"/) \
            .without_content(/"notes"/)
        }
      end
      describe 'with ttl' do
        let(:params) {{
          'ttl' => '30s',
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"ttl" *: *"30s"/)
        }
      end
      describe 'with ttl and service_id' do
        let(:params) {{
          'ttl' => '30s',
          'service_id' => 'my_service'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"ttl" *: *"30s"/) \
            .with_content(/"service_id" *: *"my_service"/)
        }
      end
      describe 'reload service with ttl and token' do
        let(:params) {{
          'ttl'   => '30s',
          'token' => 'too-cool-for-this-ttl'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"ttl" *: *"30s"/) \
            .with_content(/"token" *: *"too-cool-for-this-ttl"/) \
            .that_notifies("Class[consul::reload_service]") \
        }
      end
      describe 'with tcp' do
        let(:params) {{
          'tcp'      => 'localhost:80',
          'interval' => '30s',
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"tcp" *: *"localhost:80"/) \
            .with_content(/"interval" *: *"30s"/)
        }
      end
      describe 'with grpc' do
        let(:params) {{
          'grpc' => 'localhost:4244'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"grpc" *: *"localhost:4244"/)
        }
      end
      describe 'with grpc with tls' do
        let(:params) {{
          'grpc' => 'localhost:4244',
          'grpc_use_tls' => true
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"grpc" *: *"localhost:4244"/) \
            .with_content(/"grpc_use_tls" *: *"true"/)
        }
      end
      describe 'with grpc with interval' do
        let(:params) {{
          'grpc' => 'localhost:4244',
          'interval' => '10s'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"grpc" *: *"localhost:4244"/) \
            .with_content(/"interval" *: *"10s"/)
        }
      end
      describe 'with script and service_id' do
        let(:params) {{
          'tcp'        => 'localhost:80',
          'interval'   => '30s',
          'service_id' => 'my_service'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"tcp" *: *"localhost:80"/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"service_id" *: *"my_service"/)
        }
      end
      describe 'reload service with script and token' do
        let(:params) {{
          'tcp'      => 'localhost:80',
          'interval' => '30s',
          'token'    => 'too-cool-for-this-script'
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"tcp" *: *"localhost:80"/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"token" *: *"too-cool-for-this-script"/) \
            .that_notifies("Class[consul::reload_service]") \
        }
      end
      describe 'with both ttl and interval' do
        let(:params) {{
          'ttl' => '30s',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /script, http, tcp, and interval must not be defined for ttl checks/)
        }
      end
      describe 'with both ttl and script' do
        let(:params) {{
          'ttl' => '30s',
          'script' => 'true',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /script, http, tcp, and interval must not be defined for ttl checks/)
        }
      end
      describe 'with both ttl and http' do
        let(:params) {{
          'ttl' => '30s',
          'http' => 'http://localhost/health',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /script, http, tcp, and interval must not be defined for ttl checks/)
        }
      end
      describe 'with both ttl and tcp' do
        let(:params) {{
          'ttl' => '30s',
          'tcp' => 'localhost',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /script, http, tcp, and interval must not be defined for ttl checks/)
        }
      end
      describe 'with both script and http' do
        let(:params) {{
          'script' => 'true',
          'http' => 'http://localhost/health',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /script and tcp must not be defined for http checks/)
        }
      end
      describe 'with script but no interval' do
        let(:params) {{
          'script' => 'true',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, and script checks/)
        }
      end
      describe 'with http but no interval' do
        let(:params) {{
          'http' => 'http://localhost/health',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, and script checks/)
        }
      end
      describe 'with tcp but no interval' do
        let(:params) {{
          'tcp' => 'localhost',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, and script checks/)
        }
      end
      describe 'with a / in the id' do
        let(:params) {{
          'ttl' => '30s',
          'service_id' => 'my_service',
          'id' => 'aa/bb',
        }}
        it { should contain_file("/etc/consul/check_aa_bb.json") \
            .with_content(/"id" *: *"aa\/bb"/)
        }
      end
      describe 'with multiple / in the id' do
        let(:params) {{
          'ttl' => '30s',
          'service_id' => 'my_service',
          'id' => 'aa/bb/cc',
        }}
        it { should contain_file("/etc/consul/check_aa_bb_cc.json") \
            .with_content(/"id" *: *"aa\/bb\/cc"/)
        }
      end
    end
  end
end
