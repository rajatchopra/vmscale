#!/bin/bash

OUTFILE=${1:-/tmp/pod_time.out}

init_date=$(date)
while true; do
all_pending=$(oc get pods -o wide | grep none | wc -l)
if [ "$all_pending" == "0" ]; then 
  echo "cleared" 
  end_date=$(date)
  echo "Time taken: ${init_date} to ${end_date}"
  exit 0
else echo "${all_pending}" >> $OUTFILE
fi
sleep 1
done
