class nubis_apache::exporter($port=80) {
$apache_exporter_version = '0.4.0'
$apache_exporter_url = "https://github.com/Lusitaniae/apache_exporter/releases/download/v${apache_exporter_version}/apache_exporter-${apache_exporter_version}.linux-amd64.tar.gz"

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
  target => "/opt/apache_exporter-${apache_exporter_version}.linux-amd64/apache_exporter"
}

case $::osfamily {
  'RedHat': {
    $apache_exporter_default = '/etc/sysconfig/apache_exporter'
  }
  'Debian': {
    $apache_exporter_default = '/etc/default/apache_exporter'
  }
  default: {
    fail("Unsupported OS for apache_exporter ${::osfamily}")
  }
}

if ($::systemd) {
  file { '/lib/systemd/system/apache_exporter.service':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/apache_exporter.systemd",
  }->
  service { 'apache_exporter':
    enable => true,
  }
}
else {
  case $::osfamily {
    'RedHat': {
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
}

file { $apache_exporter_default:
  ensure  => file,
  owner   => root,
  group   => root,
  mode    => '0644',
  content => "SCRAPE_URI=http://localhost:${port}/server-status/?auto"
}

file { '/etc/consul/svc-apache-exporter.json':
  ensure => file,
  owner  => root,
  group  => root,
  mode   => '0644',
  source => "puppet:///modules/${module_name}/svc-apache-exporter.json",
}
}
