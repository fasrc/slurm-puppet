# slurm::common includes all the basics for slurm that everything will need
class slurm::common (
  Array  $slurm_pkgs    = ['slurm','slurm-devel','slurm-contribs','slurm-libpmi'],
  String $slurm_version = 'present',
  String $pmix_version  = 'present',
){
  ensure_packages($slurm_pkgs, {'ensure' => $slurm_version})
  ensure_packages(['pmix'], {'ensure' => $pmix_version})

  file { '/etc/slurm':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  file { '/etc/slurm/slurm.conf':
    ensure => link,
    target => '/slurm/etc/slurm/slurm.conf',
  }

  file { '/etc/slurm/topology.conf':
    ensure => link,
    target => '/slurm/etc/slurm/topology.conf',
  }
}
