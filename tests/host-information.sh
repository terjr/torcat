#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/functions.sh" ] && . "${DIRNAME}/functions.sh"

echo '-----BEGIN hostname-----'
hostname
echo '-----END hostname-----'

if [ -f /etc/resolv.conf ]; then
  echo '-----BEGIN /etc/resolv.conf-----'
  cat /etc/resolv.conf
  echo '-----END /etc/resolv.conf-----'
fi

if [ -x /bin/ip -o ! -z "$(which ip)" ]; then
  echo '-----BEGIN ip addr-----'
  ip addr
  echo '-----END ip addr-----'
elif [ -x /sbin/ifconfig -o ! -z "$(which ifconfig)" ]; then
  echo '-----BEGIN ifconfig -a-----'
  ifconfig -a
  echo '-----END ifconfig -a-----'
fi

if [ -x /bin/ip -o ! -z "$(which ip)" ]; then
  echo '-----BEGIN ip route-----'
  ip route
  echo '-----END ip route-----'
elif [ -x /sbin/route -o ! -z "$(which route)" ]; then
  echo '-----BEGIN route-----'
  route
  echo '-----END route-----'
fi

if [ -x /usr/bin/traceroute -o ! -z "$(which traceroute)" ]; then
  echo '-----BEGIN traceroute-----'
  # 8.8.8.8 google-public-dns-a.google.com
  traceroute 8.8.8.8
  echo '-----END traceroute-----'
fi

