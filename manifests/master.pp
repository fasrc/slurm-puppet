# slurm::master contains everything a slurm master will require
class slurm::master (
  Array   $slurm_master_pkgs   = ['slurm-slurmctld','slurm-slurmdbd','slurm-slurmrestd'],
  String  $service_name        = 'slurmctld',
  String  $slurmdbd_purge_time = '6month',
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
  Integer $max_open_files      = 8192,
  String  $max_stack_size      = 'infinity',
){
  include slurm::common
  include slurm::repo

  $slurm_version = $slurm::common::slurm_version
  $cluster = $slurm::common::cluster

  ensure_packages($slurm_master_pkgs, {'ensure' => $slurm_version})
  ensure_packages(['lua-posix'], {'ensure' => present})

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
    source => "puppet:///modules/filestore/slurm/${cluster}/slurm.conf",
    owner  => 'root',
    group  => 'root',
  }

  file { '/slurm/etc/slurm/topology.conf':
    source => "puppet:///modules/filestore/slurm/${cluster}/topology.conf",
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/slurm/job_submit.lua':
    source => "puppet:///modules/filestore/slurm/${cluster}/job_submit.lua",
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/slurm/slurmdbd.conf':
    content => template('slurm/slurmdbd.conf.erb'),
    owner   => 'slurm',
    group   => 'slurm_users',
    mode    => '0600',
    notify  => Service['slurmdbd'],
  }

  service { 'slurmdbd':
    ensure  => running,
    enable  => true,
    require => File['/etc/slurm/slurmdbd.conf'],
  }

  file { '/usr/local/sbin/slurm_restart':
    content => template('slurm/slurm_restart.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  service { 'slurmctld':
    name    => $service_name,
    ensure  => running,
    enable  => true,
    require => [
      File['/slurm/spool'],
      File['/etc/sysconfig/slurm'],
      File['/slurm/etc/slurm/slurm.conf'],
      File['/slurm/etc/slurm/topology.conf'],
      Service['slurmdbd'],
    ],
  }

  file { '/etc/sysconfig/slurmrestd':
    content => file('slurm/sysconfig-slurmrestd'),
    owner   => 'root',
    group   => 'root',
  }

  service { 'slurmrestd':
    ensure  => running,
    enable  => true,
    require => [
      File['/etc/slurm/slurm.conf'],
      File['/etc/sysconfig/slurmrestd'],
    ],
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

  file { '/etc/systemd/system/slurmctld.service.d':
    ensure => directory,
  }

  file { '/etc/systemd/system/slurmctld.service.d/50-ulimit.conf':
    ensure  => present,
    content => template('slurm/ulimits-dropin.erb'),
    require => File['/etc/systemd/system/slurmctld.service.d'],
  }
}
