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
      describe 'with no valid args' do
        let(:params) {{
          'fakecheck' => 'http://zombo.com'
        }}
        it {
          expect {
            should raise_error(Puppet::Error, /one of the following check types must be defined: http, tcp, grpc, script, or ttl/)
          }
        }
      end
      describe 'with script' do
        let(:params) {{
          'interval' => '30s',
          'script'   => 'true'
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
          'args'     => ['sh', '-c', 'true', '1', 2],
        }}
        it {
          should contain_file("/etc/consul/check_my_check.json") \
            .with_content(/"id" *: *"my_check"/) \
            .with_content(/"name" *: *"my_check"/) \
            .with_content(/"check" *: *\{/) \
            .with_content(/"interval" *: *"30s"/) \
            .with_content(/"args" *: *\[ *"sh", *"-c", *"true", *"1", *"2" *\]/)
        }
      end
      describe 'with script and service_id' do
        let(:params) {{
          'interval'   => '30s',
          'script'     => 'true',
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
          'interval' => '30s',
          'http'     => 'localhost'
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
          'interval'   => '30s',
          'http'       => 'localhost',
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
          'interval' => '30s',
          'http'     => 'localhost'
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
          'ttl'        => '30s',
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
          should raise_error(Puppet::Error, /interval must not be defined for ttl checks/)
        }
      end
      describe 'with both ttl and script' do
        let(:params) {{
          'ttl'      => '30s',
          'script'   => 'true',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /multiple check types cannot be specified in a single check definition/)
        }
      end
      describe 'with both ttl and http' do
        let(:params) {{
          'ttl'      => '30s',
          'http'     => 'http://localhost/health',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /multiple check types cannot be specified in a single check definition/)
        }
      end
      describe 'with both ttl and tcp' do
        let(:params) {{
          'ttl'      => '30s',
          'tcp'      => 'localhost',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /multiple check types cannot be specified in a single check definition/)
        }
      end
      describe 'with both script and http' do
        let(:params) {{
          'script'   => 'true',
          'http'     => 'http://localhost/health',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /multiple check types cannot be specified in a single check definition/)
        }
      end
      describe 'with both script and grpc' do
        let(:params) {{
          'script'   => 'true',
          'grpc'     => 'localhost:9000/svc',
          'interval' => '60s'
        }}
        it {
          should raise_error(Puppet::Error, /multiple check types cannot be specified in a single check definition/)
        }
      end
      describe 'with script but no interval' do
        let(:params) {{
          'script' => 'true',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, grpc, and script checks/)
        }
      end
      describe 'with http but no interval' do
        let(:params) {{
          'http' => 'http://localhost/health',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, grpc, and script checks/)
        }
      end
      describe 'with tcp but no interval' do
        let(:params) {{
          'tcp' => 'localhost',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, grpc, and script checks/)
        }
      end
      describe 'with grpc but no interval' do
        let(:params) {{
          'grpc' => 'localhost:9000',
        }}
        it {
          should raise_error(Puppet::Error, /interval must be defined for tcp, http, grpc, and script checks/)
        }
      end
      describe 'with a / in the id' do
        let(:params) {{
          'ttl'        => '30s',
          'service_id' => 'my_service',
          'id'         => 'aa/bb',
        }}
        it { should contain_file("/etc/consul/check_aa_bb.json") \
            .with_content(/"id" *: *"aa\/bb"/)
        }
      end
      describe 'with multiple / in the id' do
        let(:params) {{
          'ttl'        => '30s',
          'service_id' => 'my_service',
          'id'         => 'aa/bb/cc',
        }}
        it { should contain_file("/etc/consul/check_aa_bb_cc.json") \
            .with_content(/"id" *: *"aa\/bb\/cc"/)
        }
      end
    end
  end
end
