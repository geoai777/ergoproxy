#!/bin/bash

# Remember to put correct version of lua interpreter here
luaRT="/usr/bin/lua5.3"
dPath="/srv/dnstls"

workers=(worker-ep1053 worker-ep1054 worker-ep1055)

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
