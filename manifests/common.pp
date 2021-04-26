# slurm::common includes all the basics for slurm that everything will need
class slurm::common (
  $slurm_pkgs    = ['slurm','slurm-devel','slurm-contribs','slurm-libpmi']
  $slurm_version = 'present'
  $pmix_version  = 'present'
){
  ensure_packages($slurm_pkgs, {'ensure' => $slurm_version})
  ensure_packages(['pmix'], {'ensure' => $pmix_version})

  file { '/etc/slurm':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }
}
