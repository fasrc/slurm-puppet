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

  file { '/scratch/slurm':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0777',
    backup => false,
  }

  file { '/usr/local/bin/slurm_prolog':
    content => template('slurm/slurm_prolog.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/local/bin/slurm_task_prolog':
    content => template('slurm/slurm_task_prolog.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/local/bin/slurm_epilog':
    content => template('slurm/slurm_epilog.erb'),
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

  file { '/etc/slurm/job_container.conf' :
    source  => 'puppet:///modules/slurm/job_container.conf',
    owner   => 'root',
    group   => 'root',
    require => [
      Package['slurm'],
      File['/etc/slurm'],
    ],
  }

  file { '/etc/slurm/oci.conf' :
    source  => 'puppet:///modules/slurm/oci.conf',
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
      File['/usr/local/bin/slurm_prolog'],
      File['/usr/local/bin/slurm_task_prolog'],
      File['/usr/local/bin/slurm_epilog'],
      File['/usr/local/bin/node_monitor'],
      File['/etc/slurm/cgroup.conf'],
      File['/etc/slurm/job_container.conf'],
      File['/etc/slurm/oci.conf'],
      File['/etc/slurm/slurm.conf'],
      File['/etc/slurm/topology.conf'],
      Mount['/slurm/etc'],
    ],
  }
}
