#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/functions.sh" ] && . "${DIRNAME}/functions.sh"

# TODO: Pass IP address too so packet capture will capture on *or* specify host name and add the HTTP header...
HTTP_CONNECT_URL=$1
HTTP_CONNECT_HOST_HEADER=$2

while read SCHEME HOST PORT; do
  HTTP_CONNECT_SCHEME=${SCHEME}
  HTTP_CONNECT_HOST=${HOST}
  HTTP_CONNECT_PORT=${PORT}
  if [ -z "${HTTP_CONNECT_PORT}" ]; then
    if [ "${HTTP_CONNECT_SCHEME}" == "http" ]; then
      HTTP_CONNECT_PORT=80
    elif [ "${HTTP_CONNECT_SCHEME}" == "https" ]; then
      HTTP_CONNECT_PORT=443
    fi
  fi
done < <(echo ${HTTP_CONNECT_URL} \
       | sed 's/\([^:]*\):\/\/\([^:/]*\):\?\([^/]*\).*/\1 \2 \3/g')

HTTP_CONNECT_TIMEOUT_SECONDS=5

if [ ! -z "$(which curl)" ]; then
  HTTP_CONNECT="curl"
  HTTP_CONNECT_OPTIONS="--verbose --silent --insecure"
elif [ ! -z "$(which wget)" ]; then
  HTTP_CONNECT="wget"
  HTTP_CONNECT_OPTIONS="--debug --no-check-certificate"
else
  echo "error: missing either 'curl' or 'wget' command" 1>&2
  exit 1
fi

start_packet_capture -nn -p -s 0 -w http-connect-${HTTP_CONNECT_HOST}-${HTTP_CONNECT_PORT}.pcap -i any host ${HTTP_CONNECT_HOST} and tcp port ${HTTP_CONNECT_PORT}
HTTP_CONNECT_PCAP_PID=$!

if [ ! -z "${HTTP_CONNECT_HOST_HEADER}" ]; then
  if [ "curl" == "${HTTP_CONNECT}" ]; then
    ${HTTP_CONNECT} ${HTTP_CONNECT_OPTIONS} --header "Host: ${HTTP_CONNECT_HOST_HEADER}" $1
  elif [ "curl" == "${HTTP_CONNECT}" ]; then
    # TODO: Add Host header for wget...
    ${HTTP_CONNECT} ${HTTP_CONNECT_OPTIONS} $1
  fi
else
  ${HTTP_CONNECT} ${HTTP_CONNECT_OPTIONS} $1
fi

end_packet_capture ${HTTP_CONNECT_PCAP_PID}



