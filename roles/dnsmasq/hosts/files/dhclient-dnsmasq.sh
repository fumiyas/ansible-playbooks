#!/bin/bash
##
## Hook script for ISC dhclient(8) on Red Hat Enterprise Linux
##

dnsmasq_resolv_conf="/etc/dnsmasq.resolv.conf"

_dnsmasq_inet_aton() {
  local n ip_uint32=0

  for n in ${1//./ }; do
    let 'ip_uint32=ip_uint32 * 256 + n'
  done
  echo $ip_uint32
}

dnsmasq_config() {
  local server
  local resolv_conf_tmp="$dnsmasq_resolv_conf.$$.tmp"

  : >"$resolv_conf_tmp"
  for server in ${new_domain_name_servers-}; do
    echo "nameserver $server" >>"$resolv_conf_tmp"
  done
  mv "$resolv_conf_tmp" "$dnsmasq_resolv_conf"

  if type dbus-send >/dev/null 2>&1; then
    local dnsmasq_servers

    dnsmasq_servers=$(
      for server in $new_domain_name_servers; do
	echo -n uint32:
	_dnsmasq_inet_aton "$server"
      done
    )

    dbus-send \
      --system \
      --dest='uk.org.thekelleys.dnsmasq' \
      /uk/org/thekelleys/dnsmasq \
      uk.org.thekelleys.SetServers \
      "$dnsmasq_servers" \
    ;
  else
    ## reload not suported
    service dnsmasq restart
  fi
}

dnsmasq_restore() {
  : >"$dnsmasq_resolv_conf"

  ## reload not suported
  service dnsmasq restart
}

