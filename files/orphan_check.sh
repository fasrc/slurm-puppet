#!/bin/bash
# For a variety of reasons Slurm may miss user processes or fail to fully terminate them. This can create a situation of orphaned user processes on a node.
# This script acts as an independent check on slurm to close nodes that have user processes for users with no processes in Slurm's cgroup tree on the node.
# This script exempts checking for admin users as well as anything in subuid space because there should be an owning parent process for those owned by the original user.

set -o errexit -o nounset -o pipefail

# Get current host name
hostname=$(hostname -s)

# Collect effective UIDs and cgroup membership in one process listing.
# Ignore CrowdStrike's falcon-sensor.service, which spawns falcon-fuse helpers under user UIDs.
# Use [.] rather than \. so gawk -v does not warn on escape sequences.
falcon_service_re='^[[:space:]]*[0-9]+[[:space:]]+0::/system[.]slice/falcon-sensor[.]service(/|$)'
procs=$(ps -e -ww -o uid=,cgroup= | awk -v re="$falcon_service_re" '$0 !~ re')

# Get list of users running processes
users=$(awk '{print $1}' <<< "$procs" | sort -un)

# Users with processes in Slurm's cgroup tree: running, suspended, or completing jobs, and ssh sessions adopted
# into a job's extern step by pam_slurm_adopt. Needs no slurmctld RPC. Requires that sshd's PAM stack not run
# pam_systemd, which would move ssh sessions out of the job.
# The match is anchored to the start of the cgroup field because users can create cgroups with arbitrary names
# (e.g. "slurmstepd.scope", or names containing spaces) under user@UID.service.
# Slurm keeps a "slurmstepd infinity" process in this scope, so finding none means the cgroup layout isn't
# as expected: abort rather than treat every job's user as orphaned.
slurm_scope_re='^[[:space:]]*[0-9]+[[:space:]]+0::/system[.]slice/slurmstepd[.]scope(/|$)'
slurm_procs=$(grep -E "$slurm_scope_re" <<< "$procs") || {
  echo "No processes found in /system.slice/slurmstepd.scope" >&2
  exit 1
}
slurm_users=$(awk '{print $1}' <<< "$slurm_procs" | sort -un)

# Thresholds for minimum and maximum uid for a user. UIDs <= minthreshold are system users, UIDs >= maxthreshold are subuids.
minthreshold=1000
maxthreshold=100000000

# Set once the node is drained (or found already closed) so later users only get linger disabled and their
# user manager stopped.
node_closed=false

for u in $users
do
  # skip processes owned by system users, subuids, and users with processes in Slurm jobs
  if (( u <= minthreshold || u >= maxthreshold )) || grep -qw "$u" <<< "$slurm_users"
  then
    continue
  fi

  # skip admin users. If the lookup fails (e.g., SSSD can't reach LDAP and has no cached entry),
  # errexit aborts rather than treating an admin as a regular user.
  user_groups=$(id -Gn "$u")
  case " $user_groups " in
    *" rc_admin "*|*" kempner_sysadmin "*) continue ;;
  esac

  # Re-check just before acting: skip if this user now has processes in a Slurm job.
  # A ps failure aborts (pipefail); a user with no processes left yields empty output.
  user_procs=$(ps -e -ww -o uid=,cgroup= | awk -v uid="$u" '$1 == uid')
  if grep -qE "$slurm_scope_re" <<< "$user_procs"
  then
    continue
  fi

  # Disable linger as this can be inherited, then stop the user manager and wait for it to exit:
  # disable-linger alone returns before systemd --user is gone, and the process check below would still see it.
  loginctl disable-linger "$u"
  systemctl stop "user@$u.service"

  # If other processes (outside Slurm and Falcon) still exist, close the node.
  # Known race: a job for this user that starts after the re-check above still has the user's linger disabled
  # and user manager stopped, though excluding slurmstepd.scope here avoids draining the node for that job.
  if ! $node_closed
  then
    remaining_procs=$(
      ps -e -ww -o uid=,cgroup= |
        awk -v uid="$u" -v falcon_re="$falcon_service_re" -v slurm_re="$slurm_scope_re" \
          '$1 == uid && $0 !~ falcon_re && $0 !~ slurm_re'
    )
    if [[ -n "$remaining_procs" ]]
    then
      # Check if node is already closed for other reasons
      node_info=$(scontrol show node "$hostname")    # errexit aborts if this fails
      if ! grep -q 'Reason=' <<< "$node_info"
      then
        # Close node
        scontrol update nodename="$hostname" state=drain reason="Orphaned processes (uid: $u)"
      fi
      node_closed=true
    fi
  fi
done
