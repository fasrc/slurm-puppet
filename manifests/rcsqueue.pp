# slurm::rcsqueue installs fasrc's instance of caching squeue
class slurm::rcsqueue (
  Boolean $enable = false,
){
  if $enable {
    ensure_packages(['python3-PyMySQL'])
  }
}
