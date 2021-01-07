#!/bin/bash

dns_ip=127.0.0.1
dns_port=1053

echo "cfc9 0100 0001 0000 0000 0000 0a64 7563 6b64 7563 6b67 6f03 636f 6d00 0001 0001" | xxd -p -r | nc -q1 -w2 -n -u $dns_ip $dns_port | xxd
