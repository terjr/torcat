#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/functions.sh" ] && . "${DIRNAME}/functions.sh"

TCP_CONNECT_HOST=$1
TCP_CONNECT_PORT=$2

TCP_CONNECT_TIMEOUT_SECONDS=5

if [ ! -z "$(which ncat)" ]; then
  TCP_CONNECT="ncat"
  TCP_CONNECT_OPTIONS="--verbose --wait ${TCP_CONNECT_TIMEOUT_SECONDS}s --idle-timeout 1"
elif [ ! -z "$(which nc)" ]; then
  TCP_CONNECT="nc"
  TCP_CONNECT_OPTIONS="-v -z -w ${TCP_CONNECT_TIMEOUT_SECONDS}"
fi



start_packet_capture -nn -p -s 0 -w tcp-connect-${TCP_CONNECT_HOST}-${TCP_CONNECT_PORT}.pcap -i any host ${TCP_CONNECT_HOST} and tcp port ${TCP_CONNECT_PORT}
TCP_CONNECT_PCAP_PID=$!

${TCP_CONNECT} ${TCP_CONNECT_OPTIONS} ${TCP_CONNECT_HOST} ${TCP_CONNECT_PORT} 

end_packet_capture ${TCP_CONNECT_PCAP_PID}
wait


