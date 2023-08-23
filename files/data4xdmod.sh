#!/bin/bash
# Custom SLURM sacct query to pull data for export to xdmod nightly.
# Get yesterday's date
ndate=`date -d yesterday +%F`

# Create slurm log
TZ=UTC sacct --allusers --allclusters --parsable2 --noheader --allocations --format jobid,jobidraw,cluster,partition,qos,account,group,gid,user,uid,submit,eligible,start,end,elapsed,exitcode,state,nnodes,ncpus,reqcpus,reqmem,reqtres,alloctres,timelimit,nodelist,jobname --starttime ${ndate}T00:00:00 --endtime ${ndate}T23:59:59 > /slurm/xdmod/sacct-${ndate}.log
