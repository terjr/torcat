#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/functions.sh" ] && . "${DIRNAME}/functions.sh"

SSL_CONNECT_PCAP_PREFIX=$1
SSL_CONNECT_HOST=$2
SSL_CONNECT_PORT=$3

SSL_CONNECT_TIMEOUT_SECONDS=5

if [ -z "$(which openssl)" ]; then
  echo "error: missing 'openssl' command" 1>&2
  exit 1
fi

start_packet_capture \
  -nn \
  -p \
  -s 0 \
  -w ${SSL_CONNECT_PCAP_PREFIX}-${SSL_CONNECT_HOST}-${SSL_CONNECT_PORT}.pcap \
  -i any \
  host ${SSL_CONNECT_HOST} and tcp port ${SSL_CONNECT_PORT}
SSL_CONNECT_PCAP_PID=$!

openssl s_client -connect ${SSL_CONNECT_HOST}:${SSL_CONNECT_PORT} -debug -msg -state -showcerts </dev/null

end_packet_capture ${SSL_CONNECT_PCAP_PID}



