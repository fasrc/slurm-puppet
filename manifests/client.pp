# slurm::client includes everything needed for client hosts
class slurm::client (
  Array   $slurm_client_pkgs    = ['slurm-slurmd','slurm-pam_slurm'],
  String  $service_name         = 'slurmd',
  String  $constrain_cores      = 'yes',
  String  $constrain_ram_space  = 'yes',
  String  $constrain_swap_space = 'yes',
  String  $constrain_devices    = 'yes',
){
  include slurm::common
  include ::pam

  $slurm_version = $slurm::common::slurm_version

  ensure_packages($slurm_client_pkgs, {'ensure' => $slurm_version})

  file { '/var/slurmd':
    ensure  => directory,
    owner   => 'slurm',
    group   => 'slurm_users',
    backup  => false,
  }

  file { '/var/slurmd/run':
    ensure => directory,
    backup => false,
    owner  => 'slurm',
    group  => 'slurm_users',
  }

  file { '/var/slurmd/spool':
    ensure => directory,
    backup => false,
    owner  => 'slurm',
    group  => 'slurm_users',
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
    ]
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

  service { 'slurmd':
    name      => $service_name,
    ensure    => running,
    enable    => true,
    require   => [
      File['/var/slurmd/run'],
      File['/var/slurmd/spool'],
      File['/usr/local/bin/slurm_task_prolog'],
      File['/usr/local/bin/slurm_epilog'],
      File['/usr/local/bin/node_monitor'],
      File['/etc/slurm/cgroup.conf'],
      File['/etc/slurm/job_container.conf'],
      File['/etc/slurm/slurm.conf'],
      File['/etc/slurm/topology.conf'],
    ],
  }

  file { '/etc/pam.d/slurm':
    source  => 'puppet:///modules/slurm/pam_slurm',
    owner   => 'root',
    group   => 'root',
    require => Package['slurm-pam_slurm'],
  }

  # Add Slurm to sshd pam configuration.
  augeas { 'Enable Slurm PAM checking for SSH access':
    context => '/files/etc/pam.d/sshd',
    changes => [
      'ins 1000 before *[type = "account"][position() = 3]',
      'set 1000/type account',
      'set 1000/control required',
      'set 1000/module "pam_slurm.so"',
    ],
    onlyif  => 'match *[module = "pam_slurm.so"] size == 0',
    require => Package['slurm-pam_slurm'],
  }

  augeas { 'Enable Slurm PAM Adoption of SSH access':
    context => '/files/etc/pam.d/sshd',
    changes => [
      'ins 1000 before *[type = "account"][position() = 2]',
      'set 1000/type account',
      'set 1000/control sufficient',
      'set 1000/module "pam_slurm_adopt.so"',
    ],
    onlyif  => 'match *[module = "pam_slurm_adopt.so"] size == 0',
    require => Package['slurm-pam_slurm'],
  }

}
