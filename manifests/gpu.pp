# slurm::gpu includes things needed for gpus in addition to slurm::client
class slurm::gpu {
  file { '/etc/slurm/gres.conf':
    source => 'puppet:///modules/slurm/gres.conf',
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/slurm/prolog.d/gpustats_helper.conf':
    source  => 'puppet:///modules/slurm/prolog.d/gpustats_helper.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/slurm/prolog.d'],
  }

  file { '/etc/slurm/epilog.d/gpustats_helper.conf':
    source  => 'puppet:///modules/slurm/epilog.d/gpustats_helper.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/slurm/epilog.d'],
  }

}
