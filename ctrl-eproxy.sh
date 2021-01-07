#!/bin/bash

interpreter="/usr/bin/python3"
dPath="/srv/ergoproxy"

workers=(worker-ep1053 worker-ep1054 worker-ep1055)

if [[ $1 == "start" ]]; then
        for worker in "${workers[@]}"; do
                $interpreter $dPath/$worker &
        done
fi

if [[ $1 == "stop" ]]; then
        for worker in "${workers[@]}"; do
                pkill -f  $worker
        done
fi
