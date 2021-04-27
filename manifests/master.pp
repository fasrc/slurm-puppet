# slurm::master contains everything a slurm master will require
class slurm::master (
  String  $slurm_conf          = '',
  String  $topology_conf       = '',
  String  $jobsubmit_lua       = '',
  String  $slurmdbd_pass       = '',
  String  $slurmdbd_loc        = '',
  Integer $somaxconn           = 4096,
  Integer $syn_backlog         = 16384,
  Integer $core_rmem_max       = 8388608,
  Integer $core_wmem_max       = 8388608,
  String  $ipv4_tcp_rmem       = '4096 87380 8388608',
  String  $ipv4_tcp_wmem       = '4096 65536 8388608',
  Integer $netdev_max_backlog  = 250000,
  Integer $tcp_no_metrics_save = 1,
  Integer $tcp_moderate_rcvbuf = 1,
){
  include slurm::common
  include slurm::repo

  file { '/slurm':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  file { '/slurm/archive':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
  }

  file { '/slurm/etc':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
  }

  file { '/slurm/etc/slurm':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
  }

  file { '/slurm/spool':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
  }

  file { '/slurm/etc/slurm/slurm.conf':
    source => $slurm_conf,
    owner  => 'root',
    group  => 'root',
  }

  file { '/slurm/etc/slurm/topology.conf':
    source => $topology_conf,
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/slurm/job_submit.lua':
    source => $jobsubmit_lua,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/slurm/slurmdbd.conf':
    content => template('slurm/slurmdbd.conf.erb'),
    owner   => 'slurm',
    group   => 'slurm_users',
    mode    => '0600',
  }

# Mail settings
  file { '/etc/postfix/generic':
    content => "slurm@${::fqdn} slurm@rc.fas.harvard.edu\n",
    notify  => Exec['Build Postfix generic map'],
  }
  exec { 'Build Postfix generic map':
    command     => 'postmap hash:/etc/postfix/generic',
    refreshonly => true,
  }
  augeas { 'Rewrite slurm@hostname to slurm@rc.fas':
    context => '/files/etc/postfix/main.cf',
    changes => 'set smtp_generic_maps hash:/etc/postfix/generic',
    require => File['/etc/postfix/generic'],
    notify  => Service['postfix'],
  }

# Performance tuning
  sysctl { 'net.core.somaxconn':
    value => $somaxconn, 
  }

  sysctl { 'net.ipv4.tcp_max_syn_backlog':
    value => $syn_backlog,
  }

#CERN suggested settings https://github.com/fast-data-transfer/fdt/blob/master/docs/doc-system-tuning.md
  sysctl { 'net.core.rmem_max':
    value => $core_rmem_max,
  }

  sysctl { 'net.core.wmem_max':
    value => $core_wmem_max,
  }

  sysctl { 'net.ipv4.tcp_rmem':
    value => $ipv4_tcp_rmem,
  }

  sysctl { 'net.ipv4.tcp_wmem':
    value => $ipv4_tcp_wmem,
  }

  sysctl { 'net.core.netdev_max_backlog':
    value => $netdev_max_backlog,
  }

  sysctl { 'net.ipv4.tcp_no_metrics_save':
    value => $tcp_no_metrics_save,
  }

  sysctl { 'net.ipv4.tcp_moderate_rcvbuf':
    value => $tcp_moderate_rcvbuf,
  }
}
