# slurm::repo lays down a specific slurm repo if one is needed
class slurm::repo (
  Boolean $manage_repo  = true,
  String  $ensure       = 'present',
  Integer $enabled      = 1,
  Integer $gpgcheck     = 0,
  Integer $priority     = 99,
  String  $baseurl      = 'http://mirror-proxy.rc.fas.harvard.edu/slurm-test/centos${::operatingsystemmajrelease}',
){
  if $manage_repo {
    if $::operatingsystem =~ /(RedHat|CentOS)/ {
      yumrepo { 'slurm':
        ensure   => $ensure,
        descr    => 'slurm rpms',
        enabled  => $enabled,
        gpgcheck => $gpgcheck,
        baseurl  => $baseurl,
        priority => $priority,
      }
    }
  }
}
