# == Class consul::install
#
# Installs consul based on the parameters from init
#
class consul::install {

  case $::operatingsystem {
    'windows': {
      $binary_name = 'consul.exe'
      $binary_mode = '0775'
      $data_dir_mode = '775'
    }
    default: {
      $binary_name = 'consul'
      $binary_mode = '0555'
      $data_dir_mode = '755'
      # 0 instead of root because OS X uses "wheel".
      $binary_group = 0
    }
  }

  if $::consul::data_dir {
    file { $::consul::data_dir:
      ensure => 'directory',
      owner  => $::consul::user,
      group  => $::consul::group,
      mode   => $data_dir_mode,
    }
  }

  case $consul::install_method {
    'url': {
      $install_prefix = pick($::consul::config_hash[data_dir], '/opt/consul')
      $install_path = pick($::consul::archive_path, "${install_prefix}/archives")

      # only notify if we are installing a new version (work around for switching to archive module)
      if getvar('::consul_version') != $::consul::version {
        $do_notify_service = $::consul::notify_service
      } else {
        $do_notify_service = undef
      }

      include '::archive'
      file { [
        $install_path,
        "${install_path}/consul-${consul::version}"]:
        ensure => directory,
        owner  => $consul::user,
        group  => $consul::group,
        mode   => $binary_mode;
      }
      -> archive { "${install_path}/consul-${consul::version}.${consul::download_extension}":
        ensure       => present,
        source       => $::consul::real_download_url,
        proxy_server => $::consul::proxy_server,
        extract      => true,
        extract_path => "${install_path}/consul-${consul::version}",
        creates      => "${install_path}/consul-${consul::version}/${binary_name}",
      }
      -> file {
        "${install_path}/consul-${consul::version}/${binary_name}":
          owner =>  $consul::user,
          group => $consul::group,
          mode  => $binary_mode;
        "${consul::bin_dir}/${binary_name}":
          ensure => link,
          notify => $do_notify_service,
          target => "${install_path}/consul-${consul::version}/${binary_name}";
      }

      if ($::consul::ui_dir and $::consul::data_dir) {

        # The 'dist' dir was removed from the web_ui archive in Consul version 0.6.0
        if (versioncmp($::consul::version, '0.6.0') < 0) {
          $archive_creates = "${install_path}/consul-${consul::version}_web_ui/dist"
          $ui_symlink_target = $archive_creates
        } else {
          $archive_creates = "${install_path}/consul-${consul::version}_web_ui/index.html"
          $ui_symlink_target = "${install_path}/consul-${consul::version}_web_ui"
        }

        file { "${install_path}/consul-${consul::version}_web_ui":
          ensure => directory,
        }
        -> archive { "${install_path}/consul_web_ui-${consul::version}.zip":
          ensure       => present,
          source       => $::consul::real_ui_download_url,
          proxy_server => $::consul::proxy_server,
          extract      => true,
          extract_path => "${install_path}/consul-${consul::version}_web_ui",
          creates      => $archive_creates,
        }
        ->file { $::consul::ui_dir:
          ensure => 'symlink',
          target => $ui_symlink_target,
        }
      }
    }
    'package': {
      package { $::consul::package_name:
        ensure => $::consul::package_ensure,
        notify => $::consul::notify_service
      }

      if $::consul::ui_dir {
        package { $::consul::ui_package_name:
          ensure  => $::consul::ui_package_ensure,
          require => Package[$::consul::package_name],
          notify  => $::consul::notify_service
        }
      }

      if $::consul::manage_user {
        User[$::consul::user] -> Package[$::consul::package_name]
      }

      if $::consul::data_dir {
        Package[$::consul::package_name] -> File[$::consul::data_dir]
      }
    }
    'none': {}
    default: {
      fail("The provided install method ${consul::install_method} is invalid")
    }
  }

  if $::consul::manage_user {
    user { $::consul::user:
      ensure => 'present',
      system => true,
      groups => $::consul::extra_groups,
    }

    if $::consul::manage_group {
      Group[$::consul::group] -> User[$::consul::user]
    }
  }
  if $::consul::manage_group {
    group { $::consul::group:
      ensure => 'present',
      system => true,
    }
  }
}
