#!/bin/bash

luaRT="/usr/bin/lua5.3"
dPath="/srv/dnstls"

workers=(ergoproxy-1053 ergoproxy-1054 ergoproxy-1055)

if [[ $1 == "start" ]]; then
        for worker in "${workers[@]}"; do
                $luaRT $dPath/$worker &
        done
fi

if [[ $1 == "stop" ]]; then
        for worker in "${workers[@]}"; do
                pkill -f  $worker
        done
fi
