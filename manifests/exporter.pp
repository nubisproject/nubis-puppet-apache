class nubis_apache::exporter($port=80) {
$apache_exporter_version = '0.2'
$apache_exporter_url = "https://github.com/neezgee/apache_exporter/archive/v${apache_exporter_version}.tar.gz"

notice ("Grabbing apache_exporter ${apache_exporter_version}")
staging::file { "apache_exporter.${apache_exporter_version}.tar.gz":
  source => $apache_exporter_url,
}->
staging::extract { "apache_exporter.${apache_exporter_version}.tar.gz":
  target  => '/opt',
  creates => "/opt/apache_exporter-${apache_exporter_version}/apache_exporter"
}->
file { '/usr/local/bin/apache_exporter':
  ensure => 'link',
  target => "/opt/apache_exporter-${apache_exporter_version}/apache_exporter"
}

case $::osfamily {
  'RedHat': {
    $apache_exporter_default = '/etc/sysconfig/apache_exporter'
    file { '/etc/init.d/apache_exporter':
      ensure => file,
      owner  => root,
      group  => root,
      mode   => '0755',
      source => "puppet:///modules/${module_name}/apache_exporter.init",
    }->
    service { 'apache_exporter':
      enable => true,
    }
  }
  'Debian': {
    $apache_exporter_default = '/etc/default/apache_exporter'
    file { '/etc/init/apache_exporter.conf':
      ensure => file,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => "puppet:///modules/${module_name}/apache_exporter.upstart",
    }
  }
  default: {
    fail("Unsupported OS for apache_exporter ${::osfamily}")
  }
}

file { $apache_exporter_default:
  ensure => file,
  owner  => root,
  group  => root,
  mode   => '0644',
  content => "SCRAPE_URI=http://localhost:$port/server-status/?auto"
}

file { '/etc/consul/svc-apache-exporter.json':
  ensure => file,
  owner  => root,
  group  => root,
  mode   => '0644',
  source => "puppet:///modules/${module_name}/svc-apache-exporter.json",
}
}
