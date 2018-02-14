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

class nubis_apache(
  $project_name=$::project_name,
  $timeout=120,
  $port=80,
  $update_script_source=undef,
  $update_script_interval=undef,
  $check_url='/',
  $mpm_module_type='event',
  $tags=[],
) {

  class { '::nubis_apache::exporter':
    port => $port,
  }

  include ::nubis_apache::fluentd
  include ::nubis_apache::atomic

  if $update_script_source {
    class { 'nubis_apache::update':
      script_source   => $update_script_source,
      script_interval => $update_script_interval,
    }
  }

  include nubis_discovery

  nubis::discovery::service {
    $project_name:
      tags     => unique(sort(concat($tags, 'apache'))),
      port     => $port,
      http     => "http://localhost:${port}${check_url}",
      interval => '30s',
  }

  class {
    'apache':
        mpm_module          => $mpm_module_type,
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
        proxy_ips => [ '127.0.0.1', '10.0.0.0/8','172.16.0.0/12','192.168.0.0/16' ];
    'apache::mod::expires':
        expires_default => 'access plus 30 minutes';
  }

  # We want the default timeouts to also match our specified timeout
  # Right now, this is a missing feature in puppetlabs/apache, so we just disable mod_reqtimeout altogether
  if $::osfamily == 'Debian' {
    exec { 'fix-apache-reqtimeouts':
      command => '/usr/sbin/a2dismod reqtimeout',
      require => [
        Class['Apache::Mod::Reqtimeout'],
      ],
      path    => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
    }
  }

  file { "/etc/nubis.d/99-${project_name}":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => "#!/bin/bash -l
# Runs once on instance boot, after all infra services are up and running

# Pull latest version
if [ -x /usr/local/bin/nubis-update-site ]; then
  /usr/local/bin/nubis-update-site
fi

# Start serving it
systemctl start ${::apache::params::service_name}
"
  }
}
