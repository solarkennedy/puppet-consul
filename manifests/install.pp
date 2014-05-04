# == Class consul::intall
#
class consul::install {

  if $consul::install_method == 'url' {

    archive { 'consul':
      ensure    => 'present',
      url       => $consul::download_url,
      target    => $consul::bin_dir,
      extension => 'zip',
    } ->
    file { "$consul::bin_dir/consul":
      mode   => '0777',
      owner   => 'root',
      group   => 'root',
    }

  } elsif $consul::install_method == 'package' {

    package { $consul::package_name:
      ensure => $consul::package_ensure,
    }

  } else {
    fail("The provided install method ${consul::install_method} is invalid")
  }

  file { '/etc/init/consul.conf':
    mode   => '0444',
    owner   => 'root',
    group   => 'root',
    content => template('consul/consul.upstart.erb'),
  }

  if $consul::manage_user {
    user { $consul::user:
      ensure => 'present',
    }
  }

}
