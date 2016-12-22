# Class: nubis_apache
# ===========================
#
# Full description of class nubis_apache here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'nubis_apache':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#

class nubis_apache($timeout=120, $port=80) {

  include ::nubis_apache::exporter
  include ::nubis_apache::fluentd
  include ::nubis_apache::atomic
  
  include nubis_discovery

  nubis::discovery::service {
    $project_name:
      tags     => [ 'apache' ],
      port     => $port,
      check     => "/usr/bin/curl -If http://localhost:${port}",
      interval => '30s',
  }

  class {
    'apache':
        mpm_module          => 'event',
        keepalive           => 'On',
        timeout             => $timeout,
        keepalive_timeout   => $timeout,
        default_mods        => true,
        default_vhost       => false,
        default_confd_files => false,
        service_enable      => false,
        service_ensure      => false;
    'apache::mod::status':;
    'apache::mod::remoteip':
        proxy_ips => [ '127.0.0.1', '10.0.0.0/8' ];
    'apache::mod::expires':
        expires_default => 'access plus 30 minutes';
  }
}
