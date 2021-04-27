# slurm::master contains everything a slurm master will require
class slurm::master (
  String $slurm_conf    = '',
  String $topology_conf = '',
  String $jobsubmit_lua = '',
  String $slurmdbd_pass = '',
  String $slurmdbd_loc  = '',
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
    owner  => 'slurm'
    group  => 'slurm_users'
  }

  file { '/slurm/etc':
    ensure => directory,
    owner  => 'slurm'
    group  => 'slurm_users'
  }

  file { '/slurm/etc/slurm':
    ensure => directory,
    owner  => 'slurm'
    group  => 'slurm_users'
  }

  file { '/slurm/spool':
    ensure => directory,
    owner  => 'slurm'
    group  => 'slurm_users'
  }

  file { '/slurm/etc/slurm/slurm.conf':
    source => $slurm_conf
    owner  => 'root',
    group  => 'root',
  }

  file { '/slurm/etc/slurm/topology.conf':
    source => $topology_conf
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/slurm/job_submit.lua':
    source => $jobsubmit_lua
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/slurm/slurmdbd.conf':
    source => template('slurm/slurmdbd.conf.erb'),
    owner  => 'slurm'
    group  => 'slurm_users'
    mode   => '0600',
  }
}
