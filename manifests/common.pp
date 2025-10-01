# slurm::common includes all the basics for slurm that everything will need
class slurm::common (
  Array  $slurm_pkgs           = ['slurm','slurm-devel','slurm-contribs','slurm-libpmi','slurm-perlapi'],
  String $slurm_version        = 'present',
  String $pmix_version         = 'present',
  String $cluster              = 'test',
  String $slurm_user           = 'slurm',
  String $slurm_group          = 'slurm_users',
  String $jobstats_prom_server = '',
) {
  ensure_packages($slurm_pkgs, { 'ensure' => $slurm_version })
  ensure_packages(['pmix'], { 'ensure' => $pmix_version })

  file { '/etc/slurm':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/slurm/slurm.conf':
    ensure => link,
    target => '/slurm/etc/slurm/slurm.conf',
  }

  file { '/etc/slurm/topology.conf':
    ensure => link,
    target => '/slurm/etc/slurm/topology.conf',
  }

  file { '/etc/sysconfig/slurm':
    source => 'puppet:///modules/slurm/sysconfig-slurm',
    owner  => 'root',
    group  => 'root',
  }

  file { '/usr/local/bin/showq':
    ensure => link,
    target => '/slurm/etc/slurm/showq',
  }

  file { '/usr/local/bin/showq-slurm':
    ensure => link,
    target => '/slurm/etc/slurm/showq',
  }

  file { '/usr/local/bin/lsload':
    source => 'puppet:///modules/slurm/lsload',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/scalc':
    source => 'puppet:///modules/slurm/scalc',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/spart':
    source => 'puppet:///modules/slurm/spart',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/find-best-partition':
    source => 'puppet:///modules/slurm/find-best-partition',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/seff-array':
    source => 'puppet:///modules/slurm/seff-array.py',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/seff-account':
    source => 'puppet:///modules/slurm/seff-account',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/jobstats':
    source => 'puppet:///modules/slurm/jobstats',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/bin/jobstats.py':
    source => 'puppet:///modules/slurm/jobstats.py',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/usr/local/bin/config.py':
    content => template('slurm/jobstats-config.py.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
