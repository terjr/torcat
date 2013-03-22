#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))

[ -f "${DIRNAME}/functions.sh" ] && . "${DIRNAME}/functions.sh"

if [[ "$#" == 0 || $@ =~ .*--help([[:space:]]|$) ]]; then
  echo "$0 <name>"
  echo "<name> Name to lookup in DNS"
  exit 1
fi

if [ -z "$(which dig)" ]; then
  echo "error: missing 'dig' command" 1>&2
  exit 1
fi



start_packet_capture -nn -p -s 0 -w "dns-lookup-$1.pcap" -i any udp port 53
DNS_LOOKUP_PCAP_PID=$!

dig "$1" +trace

end_packet_capture ${DNS_LOOKUP_PCAP_PID}
