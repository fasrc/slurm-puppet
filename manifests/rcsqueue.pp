# slurm::rcsqueue installs fasrc's instance of caching squeue
class slurm::rcsqueue (
  Boolean $enable          = false,
  String  $ensure = 'present',
  String  $dbhost          = '',
  String  $dbname          = '',
  String  $dbuser          = '',
  String  $dbpass          = '',
){
  if $enable {
    ensure_packages(['python3-mysqlclient'])

    file { '/etc/profile.d/rc-squeue.sh':
      ensure  => $ensure,
      content => template ('slurm/rc-squeue.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    file { '/etc/profile.d/rc-squeue.csh':
      ensure  => $ensure,
      content => template ('slurm/rc-squeue.csh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    file { '/usr/local/bin/squeue':
      ensure => $ensure,
      source => 'puppet:///modules/slurm/rc-squeue',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }
}
