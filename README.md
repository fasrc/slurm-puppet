# slurm-puppet

## Description
This module manages slurm for Puppet 6.

### slurm::common
Installs everything needed for any slurm install.

### slurm::repo
Lays down a special repo for Slurm if needed.

### slurm::submit
Installs everything needed for a submit host in slurm.

### slurm::master
Installs everything needed for a slurm master.  Note this assumes that you are running slurmctld and slurmdbd on the same host.
