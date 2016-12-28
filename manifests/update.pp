class nubis_apache::update($script_source, $script_interval=undef) {
  file { '/usr/local/bin/nubis-update-site':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => $script_source,
  }

  if $script_interval {
    validate_hash($script_interval)

    cron { 'update-site':
      command => 'nubis-cron update-site /usr/local/bin/nubis-update-site',
      user    => 'root',
      minute  => pick($script_interval['minute'], '*'),
      hour    => pick($script_interval['hour'], '*'),
      date    => pick($script_interval['date'], '*'),
      month   => pick($script_interval['month'], '*'),
      weekday => pick($script_interval['weekday'], '*'),
    }
  }
}
