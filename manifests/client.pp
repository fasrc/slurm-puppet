# slurm::client includes everything needed for client hosts
class slurm::client (
  Array   $slurm_client_pkgs    = ['slurm-slurmd','slurm-pam_slurm'],
  String  $service_name         = 'slurmd',
  String  $service_ensure       = 'running',
  Boolean $service_enable       = true,
  String  $constrain_cores      = 'yes',
  String  $constrain_ram_space  = 'yes',
  String  $constrain_swap_space = 'yes',
  String  $constrain_devices    = 'yes',
  String  $container_scratch    = '/tmp',
  Boolean $check_kernel         = false,
  String  $kernel_version       = '4.18.0-425.10.1.el8_7.x86_64',
) {
  include slurm::common

  $slurm_version = $slurm::common::slurm_version

  ensure_packages($slurm_client_pkgs, {
      'ensure' => $slurm_version,
      'require' => [
        File['/var/slurmd/run'],
        File['/var/slurmd/spool/slurmd'],
        Mount['/slurm/etc'],
      ]
    },
  )

  file { '/var/slurmd':
    ensure  => directory,
    owner   => 'slurm',
    group   => 'slurm_users',
    backup  => false,
    require => Service['sssd'],
  }

  file { '/var/slurmd/run':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
    backup => false,
  }

  file { '/var/slurmd/spool':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
    backup => false,
  }

  file { '/var/slurmd/spool/slurmd':
    ensure => directory,
    owner  => 'slurm',
    group  => 'slurm_users',
    backup => false,
  }

  file { '/usr/local/bin/slurm_task_prolog':
    content => template('slurm/slurm_task_prolog.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/local/sbin/slurm_restart':
    content => template('slurm/slurm_restart.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/local/bin/node_monitor':
    content => template('slurm/node_monitor.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [
      Class['profile::nhc'],
    ],
  }

  file { '/etc/slurm/prolog.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/slurm/epilog.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/slurm/prolog.d/dummy.sh':
    source  => 'puppet:///modules/slurm/prolog.d/dummy.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/slurm/prolog.d'],
  }

  file { '/etc/slurm/epilog.d/dummy.sh':
    source  => 'puppet:///modules/slurm/epilog.d/dummy.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/slurm/epilog.d'],
  }


  file { '/etc/slurm/acct_gather.conf' :
    content => template('slurm/acct_gather.conf.erb'),
    owner   => 'root',
    group   => 'root',
    require => [
      Package['slurm'],
      File['/etc/slurm'],
    ],
  }

  file { '/etc/slurm/cgroup.conf' :
    content => template('slurm/cgroup.conf.erb'),
    owner   => 'root',
    group   => 'root',
    require => [
      Package['slurm'],
      File['/etc/slurm'],
    ],
  }

  file { '/etc/slurm/cgroup_allowed_devices_file.conf' :
    source  => 'puppet:///modules/slurm/cgroup_allowed_devices_file.conf',
    owner   => 'root',
    group   => 'root',
    require => [
      Package['slurm'],
      File['/etc/slurm'],
    ],
  }

  service { 'slurmd':
    ensure  => $service_ensure,
    name    => $service_name,
    enable  => $service_enable,
    require => [
      Package['slurm-slurmd'],
      Service['munge'],
      File['/var/slurmd/run'],
      File['/var/slurmd/spool/slurmd'],
      File['/etc/slurm/prolog.d'],
      File['/etc/slurm/epilog.d'],
      File['/usr/local/bin/slurm_task_prolog'],
      File['/usr/local/bin/node_monitor'],
      File['/etc/slurm/cgroup.conf'],
      File['/etc/slurm/slurm.conf'],
      File['/etc/slurm/topology.conf'],
      Mount['/slurm/etc'],
    ],
  }
}
