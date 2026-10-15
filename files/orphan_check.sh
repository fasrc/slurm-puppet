#!/bin/bash
# For a variety of reasons Slurm will miss users processes or fully terminate them. This can create a situation of orphaned user processes on a node.
# This script acts as an independent check on slurm to close nodes that have user processes for users who no longer have jobs on the node.
# This script exempts checking for admin users as well as anything in subuid space because there should be an owning parent process for those owned by the original user.

# Get current host name
hostname=$(hostname -s)

# Get list of users running processes
users=$(ps --no-header -e -o uid | sort | uniq)

# Get list of users who have jobs on this node
slurm_users=$(sacct -N ${hostname} -o UID --noheader --state=R -X | sort | uniq)

# Get list of users in rc_admin
rcadmin_users=$(getent group rc_admin | cut -d ':' -f 4 | tr ',' ' ' | xargs -n1 | sort | uniq | xargs getent passwd {} | cut -d ':' -f 3)

# Get list of users in kempner_sysadmin
kempnersysadmin_users=$(getent group kempner_sysadmin | cut -d ':' -f 4 | tr ',' ' ' | xargs -n1 | sort | uniq | xargs getent passwd {} | cut -d ':' -f 3)

# Thresholds for minimum and maximum uid for a user. Things below 1000 are system users, things above maxthreshold are subuid
minthreshold=1000
maxthreshold=100000000

for u in $users
do
  if (( $(echo "$u > $minthreshold" | bc -l) ))
  then
    if (( $(echo "$u < $maxthreshold" | bc -l) ))
    then
      ignore=0
      # Check if user is in rc_admin
      for r in $rcadmin_users
      do
        if [ $u == $r ]
        then
          ignore=1
        fi
      done

      # Check if user is in kempner_sysadmin
      for r in $kempnersysadmin_users
      do
        if [ $u == $r ]
        then
          ignore=1
        fi
      done

      # Check if user is running slurm job
      for s in $slurm_users
      do
        if [ $u = $s ]
        then
          ignore=1
        fi
      done

      # See if we can ignore this user or not.
      if [ $ignore == "0" ]
      then
        # Disable linger as this can be inherited
        loginctl disable-linger $u

        currentps=$(pgrep -u $u | wc -l)

        # If other processes exist close node
        if [ $currentps != 0 ]
        then
          # Check if node is already closed for other reasons
          if [ -z "$(scontrol show node $hostname | grep Reason)" ]
          then
            # Close node
            scontrol update nodename="$hostname" state=drain reason="Orphaned processes"
          fi
        fi
      fi
    fi
  fi
done
