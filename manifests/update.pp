class nubis_apache::update($script_source, $script_interval=undef) {
  file { '/usr/local/bin/nubis-update-site':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => $script_source,
  }

  if $script_interval {
    cron::job { 'update-site':
      command => 'nubis-cron update-site /usr/local/bin/nubis-update-site',
      user    => 'root',
      *       => $script_interval,
    }
  }
}
