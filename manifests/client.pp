# slurm::client includes everything needed for client hosts
class slurm::client (
  Array   $slurm_client_pkgs   = ['slurm-slurmd','slurm-pam_slurm'],
){
  include slurm::common

  $slurm_version = $slurm::common::slurm_version

  ensure_packages($slurm_client_pkgs, {'ensure' => $slurm_version})

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
}
