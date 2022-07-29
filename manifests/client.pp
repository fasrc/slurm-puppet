# slurm::client includes everything needed for client hosts
class slurm::client (
  Array   $slurm_client_pkgs   = ['slurm-slurmd','slurm-pam_slurm'],
){
  include slurm::common

  $slurm_version = $slurm::common::slurm_version

  ensure_packages($slurm_client_pkgs, {'ensure' => $slurm_version})
}
