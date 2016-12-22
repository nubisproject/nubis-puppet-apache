class { 'fluentd':
  service_ensure => stopped
}

fluentd::install_plugin { 'prometheus':
  ensure      => '0.2.1',
  plugin_name => 'fluent-plugin-prometheus',
  plugin_type => 'gem',
}

fluentd::configfile { 'apache': }

fluentd::source { 'apache_prometheus':
  configfile => 'apache',
  type       => 'prometheus',
  config     => {
    'port'     => '9108',
  },
}

fluentd::source { 'apache_access':
  configfile => 'apache',
  type       => 'tail',
  format     => 'apache2',
  tag        => 'forward.apache.access',
  config     => {
    'path'     => '/var/log/apache2/*access*log',
    'pos_file' => '/var/log/apache2/access.log.pos',
  },
}

fluentd::source { 'apache_error':
  configfile => 'apache',
  type       => 'tail',
  format     => '/^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\] \[pid (?<pid>[^\]]*)\] \[client (?<client>[^\]]*)\] (?<message>.*)$/',
  tag        => 'forward.apache.error',
  config     => {
    'path'     => '/var/log/apache2/*error.log',
    'pos_file' => '/var/log/apache2/error.log.pos',
  },
}

fluentd::filter { 'apache_prometheus':
      configfile => 'apache',
      pattern    => 'forward.apache.access',
      type       => 'prometheus',
# lint:ignore:single_quote_string_with_variables
      config     => {
        '<metric>' => '
    name apache_cnt_method_code_path
    type counter
    desc Apache requests broken by method, status code and path
    <labels>
      method ${method}
      code   ${code}
      path   ${path}
    </labels>
  </metric>
  <metric>
    name apache_cnt_method_code
    type counter
    desc Apache requests broken by method and status code
    <labels>
      method ${method}
      code   ${code}
    </labels>
  </metric>
  <metric>
    name apache_cnt_code
    type counter
    desc Apache requests b roken by status code
    <labels>
      code   ${code}
    </labels>
  </metric>
',
# lint:endignore
      }
    }
