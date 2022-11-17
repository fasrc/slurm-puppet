# slurm::gpu includes things needed for gpus in addition to slurm::client
class slurm::gpu {
  file { '/etc/slurm/gres.conf':
    source => 'puppet:///modules/slurm/gres.conf',
    owner  => 'root',
    group  => 'root',
  }
}
