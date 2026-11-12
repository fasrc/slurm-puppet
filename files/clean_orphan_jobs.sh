#!/bin/bash
# This script cleans up orphaned jobs

# First lets clean the orphan jobs in the slurmdbd
/usr/bin/sacctmgr -i show runawayjobs

# Second lets cancel any jobs that will clearly never run.
orphan_jobs=$(squeue --noheader -o "%A %R" --state=PD | grep -e "BadConstraints" -e "DependencyNeverSatisfied" -e "JobHeldUser" | cut -d ' ' -f 1)

for j in $orphan_jobs
do
  echo "Canceling Orphan Job $j"
  scancel $j
done

