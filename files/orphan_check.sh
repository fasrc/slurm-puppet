#!/bin/bash
# For a variety of reasons Slurm will miss users processes or fully terminate them. This can create a situation of orphaned user processes on a node.
# This script acts as an independent check on slurm to close nodes that have user processes for users who no longer have jobs on the node.
# This script exempts checking for admin users as well as anything in subuid space because there should be an owning parent process for those owned by the original user.

set -o errexit -o nounset -o pipefail

# Random sleep to stagger runs of this.
sleep $((RANDOM % 540))

# Get current host name
hostname=$(hostname -s)

# Get list of users running processes
users=$(ps --no-header -e -o uid | sort -u)

slurm_users=$(squeue --all --noheader --nodelist="$hostname" --format='%U' | sort -u)

# Thresholds for minimum and maximum uid for a user. UIDs <= minthreshold are system users, UIDs >= maxthreshold are subuids.
minthreshold=1000
maxthreshold=100000000

# Set once the node is drained (or found already closed) so later users only get linger disabled and their
# user manager stopped.
node_closed=false

for u in $users
do
  # skip processes owned by system users, subuids, and users with running Slurm jobs
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

  # Disable linger as this can be inherited, then stop the user manager and wait for it to exit:
  # disable-linger alone returns before systemd --user is gone, and pgrep below would still see it.
  loginctl disable-linger "$u"
  systemctl stop "user@$u.service"

  # If other processes exist close node.
  # Known race: a job for this user that starts after the squeue snapshot isn't in slurm_users, so the user's
  # linger is disabled, their user manager stopped, and the job's processes counted here. Re-checking only
  # the PIDs seen by the earlier ps would avoid the false drain, but not the linger and manager changes.
  if ! $node_closed && pgrep -u "$u" >/dev/null
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
done
