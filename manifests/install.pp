# == Class consul::install
#
# Installs consul based on the parameters from init
#
class consul::install {

  if $consul::data_dir {
    file { $consul::data_dir:
      ensure => 'directory',
      owner  => $consul::user,
      group  => $consul::group,
      mode   => '0755',
    }
  }

  case $consul::install_method {
    'url': {
      include staging
      staging::file { "consul-${consul::version}.${consul::download_extension}":
        source => $consul::real_download_url,
      } ->
      file { "${::staging::path}/consul-${consul::version}":
        ensure => directory,
      } ->
      staging::extract { "consul-${consul::version}.${consul::download_extension}":
        target  => "${::staging::path}/consul-${consul::version}",
        creates => "${::staging::path}/consul-${consul::version}/consul",
      }

      file {
        "${::staging::path}/consul-${consul::version}/consul":
          owner   => 'root',
          group   => 0, # 0 instead of root because OS X uses "wheel".
          mode    => '0555',
          require => Staging::Extract["consul-${consul::version}.${consul::download_extension}"];
        "${consul::bin_dir}/consul":
          ensure => link,
          notify => $consul::notify_service,
          target => "${::staging::path}/consul-${consul::version}/consul",
          require => Staging::Extract["consul-${consul::version}.${consul::download_extension}"];
      }

      if ($consul::ui_dir and $consul::data_dir) {

        # The 'dist' dir was removed from the web_ui archive in Consul version 0.6.0
        if (versioncmp($::consul::version, '0.6.0') < 0) {
          $staging_creates = "${consul::data_dir}/${consul::version}_web_ui/dist"
          $ui_symlink_target = $staging_creates
        } else {
          $staging_creates = "${consul::data_dir}/${consul::version}_web_ui/index.html"
          $ui_symlink_target = "${consul::data_dir}/${consul::version}_web_ui"
        }

        file { "${consul::data_dir}/${consul::version}_web_ui":
          ensure => 'directory',
          owner  => 'root',
          group  => 0, # 0 instead of root because OS X uses "wheel".
          mode   => '0755',
        } ->
        staging::deploy { "consul_web_ui-${consul::version}.zip":
          source  => $consul::real_ui_download_url,
          target  => "${consul::data_dir}/${consul::version}_web_ui",
          creates => $staging_creates,
        } ->
        file { $consul::ui_dir:
          ensure => 'symlink',
          target => $ui_symlink_target,
        }
      }
    }
    'package': {
      package { $consul::package_name:
        ensure => $consul::package_ensure,
      }

      if $consul::ui_dir {
        package { $consul::ui_package_name:
          ensure  => $consul::ui_package_ensure,
          require => Package[$consul::package_name]
        }
      }

      if $consul::manage_user {
        User[$consul::user] -> Package[$consul::package_name]
      }

      if $consul::data_dir {
        Package[$consul::package_name] -> File[$consul::data_dir]
      }
    }
    'none': {}
    default: {
      fail("The provided install method ${consul::install_method} is invalid")
    }
  }

  if $consul::manage_user {
    user { $consul::user:
      ensure => 'present',
      system => true,
      groups => $consul::extra_groups,
    }

    if $consul::manage_group {
      Group[$consul::group] -> User[$consul::user]
    }
  }
  if $consul::manage_group {
    group { $consul::group:
      ensure => 'present',
      system => true,
    }
  }
}
