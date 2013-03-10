#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/functions.sh" ] && . "${DIRNAME}/functions.sh"

TOR_CONNECT_URL=$1

while read HOST PORT; do
  TOR_CONNECT_HOST=$HOST
  TOR_CONNECT_PORT=$PORT
done < <(echo ${TOR_CONNECT_URL} | sed 's/:/ /g')

start_packet_capture \
  -nn \
  -p \
  -s 0 \
  -w tor-consensus-${TOR_CONNECT_HOST}-${TOR_CONNECT_PORT}.pcap \
  -i any \
  host ${TOR_CONNECT_HOST} and tcp port ${TOR_CONNECT_PORT}
TOR_CONNECT_PCAP_PID=$!

wget \
  --debug \
  --output-document=status-vote-current-consensus-${TOR_CONNECT_HOST}-${TOR_CONNECT_PORT} \
  --connect-timeout=5 \
  --read-timeout=30 \
  --tries=1 \
  http://${TOR_CONNECT_HOST}:${TOR_CONNECT_PORT}/tor/status-vote/current/consensus

end_packet_capture ${TOR_CONNECT_PCAP_PID}
wait
