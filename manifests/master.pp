# slurm::master contains everything a slurm master will require
class slurm::master {
  include slurm::common
  include slurm::repo
}
