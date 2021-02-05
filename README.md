# eЯgo pЯoxy
Simple DNS UDP to TCP proxy script. 
Workder script is based on this [this](https://gist.github.com/korc/68f3a9c00f92062346603265bdca721c) code. I slightly modified it for variable setup convenience.

**Please be advise**, I use three proxy workers, each on other port. If you desire to do so, you should edit port name in worker script and save files with according names. The same applies to Stunnel config. If you intend to use less workers you should edit it accordingly. 

zer0. You can simply
```
dpkg -i ergoproxy-2.0.deb
```
instead of p.2,3,4 and 6.

1. Install stunnel and copy [stu.conf](https://github.com/p0rc0jet/ergoproxy/blob/master/stu.conf) (edit if needed) to `/etc/stunnel/`
```
apt install stunnel4
```

2. Now, copy [`worker-ep1053`](https://raw.githubusercontent.com/p0rc0jet/ergoproxy/master/worker-ep1053) to `worker-ep1054`...`worker-ep1055`, remember to edit **ports** according to your needs.<br>


3. Put [ctrl-eproxy.sh](https://github.com/p0rc0jet/ergoproxy/blob/master/ctrl-eproxy.sh) to `/srv/dnstls`.

4. Finally put [eproxy.service](https://github.com/p0rc0jet/ergoproxy/blob/master/eproxy.service) to `/etc/systemd/system/`.
```
systemctl enable eproxy.service
```

5. Add following to `/etc/bind/named.conf.options`:
```
  forwarders {
    127.0.0.1 port 1053;
    127.0.0.1 port 1054;
    127.0.0.1 port 1055;
  }
```

6. Start service.
```
systemctl start eproxy.service
```

7. Restart DNS server (bind)
```
systemctl restart bind9.service
```
7.1. Run script to test your eproxy + stunnel is working
```
eproxy_test.sh
```
will give you something like:
```
00000000: cfc9 8180 0001 0001 0000 0000 0a64 7563  .............duc
00000010: 6b64 7563 6b67 6f03 636f 6d00 0001 0001  kduckgo.com.....
00000020: c00c 0001 0001 0000 007e 0004 2872 b19c  .........~..(r..
```
this means everything works well.

8. (Optional) Restrict all DNS FORWARDING on your firewall so clients use only secure DNS server.

I hope it helps.

# Links
- https://gist.github.com/korc/68f3a9c00f92062346603265bdca721c - udp2tcp script source
- https://github.com/ivan386/lua-simple-udp-to-tcp-dns-proxy - lua script author (old worker)
