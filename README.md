# eЯgo pЯoxy
Simple DNS UDP to TCP proxy script. 
I do not take [credit for lua script](https://github.com/ivan386/lua-simple-udp-to-tcp-dns-proxy), I just describe how I use it. 

**Please be advise**, I use three proxy workers, each on other port. If you desire to do so, you should edit port name in LUA script and save files with according names. The same applies to Stunnel config. If you intend to use less workers you should edit it accordingly. 

1. Install stunnel and copy [stu.conf](https://github.com/p0rc0jet/ergoproxy/blob/master/stu.conf) (edit if needed) to `/etc/stunnel/`
```
apt install stunnel4
```
**VERY** IMPORTANT NOTICE: At some point, stunnel can get stubborn about `verifyPeer = yes` option. Here what should be done:<br>
1.1. After `setuid` add `verifyPeer = yes`<br>
1.2. Use this command to aquire pem certificate from secure dns provider</br>
```
openssl s_client -servername $1 -connect $1:853</dev/null 2>/dev/null | openssl x509 -text
```
* - spent whole day trying to find solution for this `CERT: Certificate not found in local repository` error.<br>
1.3. Copy tail of output starting with `-----BEGIN CERTIFICATE-----` ending with `-----END CERTIFICATE-----` to file, for example `dns.google.pem`.<br>
1.4. Add file to `stu.conf` at appropriate serivce.<br>

2. Download root certificates to `/srv/dnstls`, convert to pem and run stunnel
```
wget https://secure.globalsign.net/cacert/Root-R2.crt -P /srv/dnstls
openssl x509 -inform DER -in Root-R2.crt -out Root-R2.pem -text
systemctl restart stunnel4.service
```

3. Now, here are two possibilities:<br>
3.1. Use lua file as is. AFAIK it has no performance impact. copy [`eproxy.lua`](https://github.com/p0rc0jet/ergoproxy/blob/master/eproxy.lua) to `worker-ep1053`...`worker-ep1055`, remember to edit ports according to your needs.<br>
3.2. Remember to edit ports according to your needs. Compile lua chunk with `luac eproxy.lua -o worker-ep1053`

4. Put [ctrl-eproxy.sh](https://github.com/p0rc0jet/ergoproxy/blob/master/ctrl-eproxy.sh) to `/srv/dnstls`. Remember to check there is correct lua (lua5.2, lua5.3, etc.) interpreter version in file. 

4.1. Finally put [eproxy.service](https://github.com/p0rc0jet/ergoproxy/blob/master/eproxy.service) to `/etc/systemd/system/`.
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

8. (Optional) Restrict all DNS FORWARDING on your firewall so clients use only secure DNS server.

I hope it helps.

# Links
- https://github.com/ivan386/lua-simple-udp-to-tcp-dns-proxy - lua script author
- https://habr.com/ru/post/427957/ - article on how to create TCP to UDP proxy
