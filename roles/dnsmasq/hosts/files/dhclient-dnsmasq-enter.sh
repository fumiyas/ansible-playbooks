#!/bin/sh
##
## Hook script for ISC dhclient(8) on Debian GNU/Linux
##

{
  for name_server in $new_domain_name_servers; do
    echo "nameserver $name_server"
  done
} >/etc/dnsmasq.resolv.conf

new_domain_name=''
new_domain_name_servers='127.0.0.1'
 
