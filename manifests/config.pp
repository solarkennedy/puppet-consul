# == Class consul::config
#
# This class is called from consul::init to install the config file.
#
# == Parameters
#
# [*config_hash*]
#   Hash for Consul to be deployed as JSON
#
# [*purge*]
#   Bool. If set will make puppet remove stale config files.
#
# [*enable_beta_ui*]
#   Bool. Should the UI be enabled
#
# [*allow_binding_to_root_ports*]
#   Bool. Should binding to specified ports be allowed
#
# [*restart_on_change*]
#   Bool. Should the service be restarted on changes
#
class consul::config (
  Hash    $config_hash                 = $consul::config_hash_real,
  Boolean $purge                       = $consul::purge_config_dir,
  Boolean $enable_beta_ui              = $consul::enable_beta_ui,
  Boolean $allow_binding_to_root_ports = $consul::allow_binding_to_root_ports,
  Boolean $restart_on_change           = $consul::restart_on_change,
) {

  $notify_service = $restart_on_change ? {
    true    => Class['consul::run_service'],
    default => undef,
  }

  if ($consul::init_style_real != 'unmanaged') {

    case $consul::init_style_real {
      'upstart': {
        file { '/etc/init/consul.conf':
          ensure  => file,
          mode    => '0444',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.upstart.erb'),
        }
        file { '/etc/init.d/consul':
          ensure => link,
          target => '/lib/init/upstart-job',
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }
      'systemd': {
        systemd::unit_file { 'consul.service':
          content => template('consul/consul.systemd.erb'),
          notify  => $notify_service,
        }
      }
      'init','redhat': {
        file { '/etc/init.d/consul':
          ensure  => file,
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.init.erb'),
        }
      }
      'debian': {
        file { '/etc/init.d/consul':
          ensure  => file,
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.debian.erb'),
        }
      }
      'sles': {
        file { '/etc/init.d/consul':
          ensure  => file,
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul/consul.sles.erb'),
        }
      }
      'launchd': {
        file { '/Library/LaunchDaemons/io.consul.daemon.plist':
          ensure  => file,
          mode    => '0644',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul/consul.launchd.erb'),
        }
      }
      'freebsd': {
        file { '/etc/rc.conf.d/consul':
          ensure  => file,
          mode    => '0444',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul/consul.freebsd-rcconf.erb'),
        }
        file { '/usr/local/etc/rc.d/consul':
          ensure  => file,
          mode    => '0555',
          owner   => 'root',
          group   => 'wheel',
          content => template('consul/consul.freebsd.erb'),
        }
      }
      default: {
        fail("I don't know how to create an init script for style ${consul::init_style_real}")
      }
    }
  }

  file { $consul::config_dir:
    ensure  => 'directory',
    owner   => $consul::user_real,
    group   => $consul::group_real,
    purge   => $purge,
    recurse => $purge,
  }

  file { 'consul config.json':
    ensure       => present,
    path         => "${consul::config_dir}/config.json",
    owner        => $consul::user_real,
    group        => $consul::group_real,
    mode         => $consul::config_mode,
    content      => consul::sorted_json($config_hash, $consul::pretty_config, $consul::pretty_config_indent),
    validate_cmd => "${consul::bin_dir}/${consul::binary_name} validate ${consul::config_dir}",
  }

}
