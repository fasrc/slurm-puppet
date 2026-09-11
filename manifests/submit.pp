# slurm::submit includes everything needed for submit hosts
class slurm::submit {
  include slurm::common

  file { '/usr/local/bin/watch':
    source  => 'puppet:///modules/slurm/watch',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
}
