# == Class: consul
#
# Installs, configures and manages consul
#
# === Parameters
#
# [*acls*]
#   Hash of consul_acl resources to create.
#
# [*arch*]
#   Architecture of consul binary to download.
# == Class: consul
#
# Installs, configures and manages consul
#
# === Parameters
#
# [*acls*]
#   Hash of consul_acl resources to create.
#
# [*arch*]
#   Architecture of consul binary to download.
#
# [*archive_path*]
#   Path used when installing consul via the url.
#
# [*bin_dir*]
#   Directory to create the symlink to the consul binary in.
#
# [*binary_group*]
#   The group that the file belongs to.
#
# [*binary_mode*]
#   Permissions mode for the file.
#
# [*binary_name*]
#   The binary name file.
#
# [*binary_owner*]
#   The user that owns the file.
#
# [*checks*]
#   Hash of consul::check resources to create.
#
# [*config_defaults*]
#   Configuration defaults hash. Gets merged with config_hash.
#
# [*config_dir*]
#   Directory to place consul configuration files in.
#
# [*config_hash*]
#   Use this to populate the JSON config file for consul.
#
# [*config_mode*]
#   Use this to set the JSON config file mode for consul.
#
# [*docker_image*]
#   Only valid when the install_method == docker. Defaults to `consul`.
#
# [*download_extension*]
#   The extension of the archive file containing the consul binary to download.
#
# [*download_url*]
#   Fully qualified url to the location of the archive file containing the consul binary.
#
# [*download_url_base*]
#   Base url to the location of the archive file containing the consul binary.
#
# [*extra_groups*]
#   Extra groups to add the consul system user to.
#
# [*extra_options*]
#   Extra arguments to be passed to the consul agent
#
# [*group*]
#   Name of the group that should own the consul configuration files.
#
# [*init_style*]
#   What style of init system your system uses. Set to 'unmanaged' to disable
#   managing init system files for the consul service entirely.
#   This is ignored when install_method == 'docker'
#
# [*install_method*]
#   Valid strings: `docker`  - install via docker container
#                  `package` - install via system package
#                  `url`     - download and extract from a url. Defaults to `url`.
#                  `none`    - disable install.
#
# [*join_wan*]
#   Whether to join the wan on service start.
#
# [*manage_group*]
#   Whether to create/manage the group that should own the consul configuration files.
#
# [*manage_service*]
#   Whether to manage the consul service.
#
# [*manage_user*]
#   Whether to create/manage the user that should own consul's configuration files.
#
# [*nssm_exec*]
#   Location of nssm windows binary for service management
#
# [*os*]
#   OS component in the name of the archive file containing the consul binary.
#
# [*package_ensure*]
#   Only valid when the install_method == package. Defaults to `latest`.
#
# [*package_name*]
#   Only valid when the install_method == package. Defaults to `consul`.
#
# [*pretty_config*]
#   Generates a human readable JSON config file. Defaults to `false`.
#
# [*pretty_config_indent*]
#   Toggle indentation for human readable JSON file. Defaults to `4`.
#
# [*proxy_server*]
#   Specify a proxy server, with port number if needed. ie: https://example.com:8080.
#
# [*purge_config_dir*]
#   Purge config files no longer generated by Puppet
#
# [*restart_on_change*]
#   Determines whether to restart consul agent on $config_hash changes.
#   This will not affect reloads when service, check or watch configs change.
#   Defaults to `true`.
#
# [*service_enable*]
#   Whether to enable the consul service to start at boot.
#
# [*service_ensure*]
#   Whether the consul service should be running or not.
#
# [*services*]
#   Hash of consul::service resources to create.
#
# [*user*]
#   Name of the user that should own the consul configuration files.
#
# [*version*]
#   Specify version of consul binary to download.
#
# [*watches*]
#   Hash of consul::watch resources to create.
#
# [*shell*]
#   The shell for the consul user. Defaults to something that prohibits login, like /usr/sbin/nologin
#
# [*enable_beta_ui*]
#   consul 1.1.0 introduced a new UI, which is currently (2018-05-12) in beta status. 
#   You can enable it by setting this variable to true. Defaults to false
#
# [*allow_binding_to_root_ports*]
#   Boolean, enables CAP_NET_BIND_SERVICE if true. This is currently only implemented on systemd nodes
#
# [*log_file*]
#   String, where should the log file be located
#
# === Examples
#
#  @example
#    class { 'consul':
#      config_hash => {
#        'datacenter'   => 'east-aws',
#        'node_name'    => $::fqdn,
#        'pretty_config => true,
#        'retry-join'   => ['172.16.0.1'],
#      },
#    }
#
class consul (
  Hash $acls                                 = $consul::params::acls,
  $arch                                      = $consul::params::arch,
  $archive_path                              = $consul::params::archive_path,
  $bin_dir                                   = $consul::params::bin_dir,
  $binary_group                              = $consul::params::binary_group,
  $binary_mode                               = $consul::params::binary_mode,
  $binary_name                               = $consul::params::binary_name,
  $binary_owner                              = $consul::params::binary_owner,
  Hash $checks                               = $consul::params::checks,
  Hash $config_defaults                      = $consul::params::config_defaults,
  $config_dir                                = $consul::params::config_dir,
  Hash $config_hash                          = $consul::params::config_hash,
  $config_mode                               = $consul::params::config_mode,
  $docker_image                              = $consul::params::docker_image,
  $download_extension                        = $consul::params::download_extension,
  Optional[Stdlib::HTTPUrl] $download_url    = undef,
  $download_url_base                         = $consul::params::download_url_base,
  Array $extra_groups                        = $consul::params::extra_groups,
  $extra_options                             = $consul::params::extra_options,
  $group                                     = $consul::params::group,
  $log_file                                  = $consul::params::log_file,
  $init_style                                = $consul::params::init_style,
  $install_method                            = $consul::params::install_method,
  $join_wan                                  = $consul::params::join_wan,
  Boolean $manage_group                      = $consul::params::manage_group,
  Boolean $manage_service                    = $consul::params::manage_service,
  Boolean $manage_user                       = $consul::params::manage_user,
  Optional[String] $nssm_exec                = undef,
  $os                                        = $consul::params::os,
  $package_ensure                            = $consul::params::package_ensure,
  $package_name                              = $consul::params::package_name,
  Boolean $pretty_config                     = $consul::params::pretty_config,
  Integer $pretty_config_indent              = $consul::params::pretty_config_indent,
  Optional[Stdlib::HTTPUrl] $proxy_server    = undef,
  Boolean $purge_config_dir                  = $consul::params::purge_config_dir,
  Boolean $restart_on_change                 = $consul::params::restart_on_change,
  Boolean $service_enable                    = $consul::params::service_enable,
  Enum['stopped', 'running'] $service_ensure = $consul::params::service_ensure,
  Hash $services                             = $consul::params::services,
  $user                                      = $consul::params::user,
  $version                                   = $consul::params::version,
  Hash $watches                              = $consul::params::watches,
  Optional[String] $shell                    = $consul::params::shell,
  Boolean $enable_beta_ui                    = false,
  Boolean $allow_binding_to_root_ports       = false,
) inherits consul::params {

  # lint:ignore:140chars
  $real_download_url    = pick($download_url, "${download_url_base}${version}/${package_name}_${version}_${os}_${arch}.${download_extension}")
  # lint:endignore

  $config_hash_real = deep_merge($config_defaults, $config_hash)

  if $install_method == 'docker' {
    $user_real = undef
    $group_real = undef
    $init_style_real = 'unmanaged'
  }
  elsif $::operatingsystem == 'windows' {
    $user_real = $user
    $group_real = $group
    $init_style_real = 'windows'
  } else {
    $user_real = $user
    $group_real = $group
    $init_style_real = $init_style
  }

  if $config_hash_real['data_dir'] {
    $data_dir = $config_hash_real['data_dir']
  } else {
    $data_dir = undef
  }

  if ($config_hash_real['ports'] and $config_hash_real['ports']['http']) {
    $http_port = $config_hash_real['ports']['http']
  } else {
    $http_port = 8500
  }

  if ($config_hash_real['addresses'] and $config_hash_real['addresses']['http']) {
    $http_addr = split($config_hash_real['addresses']['http'], ' ')[0]
  } elsif ($config_hash_real['client_addr']) {
    $http_addr = $config_hash_real['client_addr']
  } else {
    $http_addr = $::ipaddress_lo
  }

  if $services {
    create_resources(consul::service, $services)
  }

  if $watches {
    create_resources(consul::watch, $watches)
  }

  if $checks {
    create_resources(consul::check, $checks)
  }

  if $acls {
    create_resources(consul_acl, $acls)
  }

  $notify_service = $restart_on_change ? {
    true    => Class['consul::run_service'],
    default => undef,
  }

  anchor {'consul_first': }
  -> class { 'consul::install': }
  -> class { 'consul::config':
    config_hash => $config_hash_real,
    purge       => $purge_config_dir,
    notify      => $notify_service,
  }
  -> class { 'consul::run_service': }
  -> class { 'consul::reload_service': }
  -> anchor {'consul_last': }
}
