# == Define: consul::watch
#
# Sets up Consul watch, to span commands when data changes.
# http://www.consul.io/docs/agent/watches.html
#
# == Parameters
#
# [*config_filename*]
#   Enables backwards compatiblity, and allows you to override the name of the config file.
#
# [*datacenter*]
#   String overriding consul's default datacenter.
#
# [*ensure*]
#   Define availability of watch. Use 'absent' to remove existing watches.
#   Defaults to 'present'
#
# [*event_name*]
#   Name of an event to watch for, defaults to the resource title.
#
# [*handler*]
#   Full path to the script that will be excuted. This parameter is deprecated
#   in Consul 1.0.0, see https://github.com/hashicorp/consul/issues/3509.
#
# [*args*]
#   Arguments to be `exec`ed for the watch.
#
# [*key*]
#   Watch a specific key.
#
# [*keyprefix*]
#   Watch a whole keyprefix
#
# [*passingonly*]
#   Watch only those services that are passing healthchecks.
#
# [*service*]
#   Watch a particular service
#
# [*service_tag*]
#   This actually maps to the "tag" param for service watches.
#   (`tag` is a puppet builtin metaparameter)
#
# [*state*]
#   Watch a state change on a service healthcheck.
#
# [*token*]
#   String to override the default token.
#
# [*type*]
#   Type of data to watch. (Like key, service, services, nodes)
#
define consul::watch (
  $args                          = undef,
  $config_filename               = "watch_${title}.json",
  $datacenter                    = undef,
  $ensure                        = present,
  $event_name                    = $title,
  $handler                       = undef,
  $key                           = undef,
  $keyprefix                     = undef,
  Optional[Boolean] $passingonly = undef,
  $service                       = undef,
  $service_tag                   = undef,
  $state                         = undef,
  $token                         = undef,
  $type                          = undef,
) {
  include consul

  $basic_hash = {
    'type'       => $type,
    'args'       => $args,
    'handler'    => $handler,
    'datacenter' => $datacenter,
    'token'      => $token,
  }

  if (versioncmp($consul::version, '0.4.0') < 0) {
    fail('Watches are only supported in Consul 0.4.0 and above')
  }

  if (! $handler and ! $args) {
    fail('All watch conditions must have a handler or args list defined')
  }

  if ($handler and $args) {
    fail('Watch conditions cannot have both a handler and args list defined')
  }

  if (! $type ) {
    fail('All watch conditions must have a type defined')
  }

  case $type {
    'key': {
      if (! $key ) {
        fail('key is required for watch type [key]')
      }
      $type_hash = {
        key => $key,
      }
    }
    'keyprefix': {
      if (! $keyprefix ) {
        fail('keyprefix is required for watch type of [keyprefix]')
      }
      $type_hash = {
        prefix => $keyprefix,
      }
    }
    'service': {
      if (! $service ) {
        fail('service is required for watch type of [service]')
      }
      $type_hash = {
        service     => $service,
        tag         => $service_tag,
        passingonly => $passingonly,
      }
    }
    'checks': {
      $type_hash = {
        service => $service,
        state   => $state,
      }
    }
    'event': {
      $type_hash = {
        name => $event_name,
      }
    }
    /(nodes|services)/: {
      $type_hash = {}
    }
    default: {
      fail("${type} is an unrecogonized watch type that is not supported currently")
    }
  }

  $merged_hash = merge($basic_hash, $type_hash)

  $watch_hash = {
    watches => [$merged_hash.filter |$key, $val| { $val =~ NotUndef }],
  }

  file { "${consul::config_dir}/${config_filename}":
    ensure  => $ensure,
    owner   => $consul::user_real,
    group   => $consul::group_real,
    mode    => $consul::config_mode,
    content => consul::sorted_json($watch_hash, $consul::pretty_config, $consul::pretty_config_indent),
    notify  => Class['consul::reload_service'],
  }
}
