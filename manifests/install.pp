# == Class consul::intall
#
# Installs consule based in the parameters from init
#
class consul::install {

  if $consul::manage_user {
    user { $consul::user:
      ensure => 'present',
    }
  }
  if $consul::manage_group {
    group { $consul::group:
      ensure => 'present',
    }
  }

  case $consul::install_method {
    'url': {
      if $::operatingsystem != 'darwin' {
        ensure_packages(['unzip'])
      }
      staging::file { 'consul.zip':
        source => $consul::real_download_url
      } ->
      staging::extract { 'consul.zip':
        target  => $consul::bin_dir,
        creates => "${consul::bin_dir}/consul",
      } ->
      file { "${consul::bin_dir}/consul":
        owner => 'root',
        group => 0, # 0 instead of root because OS X uses "wheel".
        mode  => '0555',
      }

      if ($consul::ui_dir and $consul::data_dir) {
        file { "${consul::data_dir}/${consul::version}_web_ui":
          ensure => 'directory',
          owner  => 'root',
          group  => 0, # 0 instead of root because OS X uses "wheel".
          mode   => '0755',
        } ->
        staging::deploy { 'consul_web_ui.zip':
          source  => $consul::real_ui_download_url,
          target  => "${consul::data_dir}/${consul::version}_web_ui",
          creates => "${consul::data_dir}/${consul::version}_web_ui/dist",
        }
        file { $consul::ui_dir:
          ensure => 'symlink',
          target => "${consul::data_dir}/${consul::version}_web_ui/dist",
        }
      }
    }
    'package': {
      package { $consul::package_name:
        ensure => $consul::package_ensure,
      }

      if $consul::ui_dir {
        package { $consul::ui_package_name:
          ensure => $consul::ui_package_ensure,
        }
      }
    }
    'none': {}
    default: {
      fail("The provided install method ${consul::install_method} is invalid")
    }
  }

  if $consul::data_dir {
    file { $consul::data_dir:
      ensure => 'directory',
      owner  => $consul::user,
      group  => $consul::group,
      mode   => '0755',
    }
  }

}
