class nubis_apache::update($script_source) {
  file { '/usr/local/bin/nubis-update-site':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => $script_source,
  }
}
