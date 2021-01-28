# == Define consul::check
#
# Sets up a Consul healthcheck
# http://www.consul.io/docs/agent/checks.html
#
# == Parameters
#
# [*ensure*]
#   Define availability of check. Use 'absent' to remove existing checks.
#   Defaults to 'present'
#
# [*http*]
#   HTTP endpoint for the service healthcheck
#
# [*id*]
#   The id for the check (defaults to $title)
#
# [*interval*]
#   Value in seconds for the interval between runs of the check
#
# [*notes*]
#   Human readable description of the check
#
# [*script*]
#   Full path to the location of the healthcheck script. Must be nagios
#   compliant with regards to the return codes. This parameter is deprecated
#   in Consul 1.0.0, see https://github.com/hashicorp/consul/issues/3509.
#
# [*args*]
#   Arguments to be `exec`ed for the healthcheck script.
#
# [*service_id*]
#   An optional service_id to match this check against
#
# [*status*]
#   The default state of the check when it is registered against a consul
#   agent. Should be either "critical" or "passing"
#
# [*tcp*]
#   The IP/hostname and port for the service healthcheck. Should be in
#   'hostname:port' format.
#
# [*grpc*]
#   The IP/hostname and port for the service healthcheck.  Should be in
#   'hostname:port' format.
#
# [*timeout*]
#   A timeout value for HTTP request only
#
# [*token*]
#   ACL token for interacting with the catalog (must be 'management' type)
#
# [*ttl*]
#   Value in seconds before the http endpoint considers a failing healthcheck
#   to be "HARD" down.
#
# [*success_before_passing*]
#   Value may be set to become check passing only after a specified number of consecutive
#   checks return passing
#
# [*failures_before_critical*]
#   Value may be set to become check critical only after a specified number of consecutive
#   checks return critical
#
define consul::check (
  $ensure                   = present,
  $http                     = undef,
  $id                       = $title,
  $interval                 = undef,
  $notes                    = undef,
  $script                   = undef,
  $args                     = undef,
  $service_id               = undef,
  $status                   = undef,
  $tcp                      = undef,
  $grpc                     = undef,
  $timeout                  = undef,
  $token                    = undef,
  $ttl                      = undef,
  $success_before_passing   = undef,
  $failures_before_critical = undef,
) {
  include consul

  $basic_hash = {
    'id'                       => $id,
    'name'                     => $name,
    'ttl'                      => $ttl,
    'http'                     => $http,
    'script'                   => $script,
    'args'                     => $args,
    'tcp'                      => $tcp,
    'grpc'                     => $grpc,
    'interval'                 => $interval,
    'timeout'                  => $timeout,
    'service_id'               => $service_id,
    'notes'                    => $notes,
    'token'                    => $token,
    'status'                   => $status,
    'success_before_passing'   => $success_before_passing,
    'failures_before_critical' => $failures_before_critical,
  }

  $check_hash = {
    check => $basic_hash.filter |$key, $val| { $val =~ NotUndef },
  }

  consul::validate_checks($check_hash[check])

  $escaped_id = regsubst($id,'\/','_','G')
  file { "${consul::config_dir}/check_${escaped_id}.json":
    ensure  => $ensure,
    owner   => $consul::user_real,
    group   => $consul::group_real,
    mode    => $consul::config_mode,
    content => consul::sorted_json($check_hash, $consul::pretty_config, $consul::pretty_config_indent),
    notify  => Class['consul::reload_service'],
  }

}
