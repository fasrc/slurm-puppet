# slurm-puppet

> [!NOTE]
> This module is published as a demonstration only and is not portable. As written, it depends on private Puppet modules used only in our environment.

## Description
This module manages slurm for Puppet 7+.

### slurm::common
Installs everything needed for any slurm install.

### slurm::repo
Lays down a special repo for Slurm if needed.

### slurm::submit
Installs everything needed for a submit host in slurm.

### slurm::client
Installs everything needed for a slurm client.

### slurm::master
Installs everything needed for a slurm master.  Note this assumes that you are running slurmctld and slurmdbd on the same host.

### slurm::rcsqueue
Installs the caching version of squeue developed by FASRC.

