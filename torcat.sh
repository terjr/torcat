#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/tests/functions.sh" ] && . "${DIRNAME}/tests/functions.sh"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

mkdir -v "${DIRNAME}/torcat-${TIMESTAMP}" \
  && cd "${DIRNAME}/torcat-${TIMESTAMP}" \
  || exit $?

TESTS_DIR="${DIRNAME}/tests"

###############################################################################
# TEST: Gather host information
###############################################################################

function test_host_information() {
  ${TESTS_DIR}/host-information.sh > host-information.log
}

###############################################################################
# TEST: Connect to bridges.torproject.org
###############################################################################
BRIDGES_TORPROJECT_ORG_IP='38.229.72.19'

function test_bridges_torproject_org() {
  ${TESTS_DIR}/dns-lookup.sh bridges.torproject.org \
    1> dns-lookup-bridges.torproject.org.log \
    2> dns-lookup-bridges.torproject.org.err
  
  if grep -q "${BRIDGES_TORPROJECT_ORG_IP}XXX" dns-lookup-bridges.torproject.org.log; then
    ${TESTS_DIR}/tcp-connect.sh bridges.torproject.org 443 \
      1> tcp-connect-bridges.torproject.org-443.log \
      2> tcp-connect-bridges.torproject.org-443.err
  
    ${TESTS_DIR}/ssl-connect.sh ssl-connect bridges.torproject.org 443 \
      1> ssl-connect-bridges.torproject.org-443.log \
      2> ssl-connect-bridges.torproject.org-443.err
  
    ${TESTS_DIR}/http-connect.sh https://bridges.torproject.org \
      1> http-connect-bridges.torproject.org-443.log \
      2> http-connect-bridges.torproject.org-443.err
  else
    # Cannot lookup bridges.torproject.org correctly.
    # Falling back to known IP address of bridges.torproject.org
    ${TESTS_DIR}/tcp-connect.sh ${BRIDGES_TORPROJECT_ORG_IP} 443 \
      1> tcp-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log \
      2> tcp-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.err
    ${TESTS_DIR}/ssl-connect.sh ssl-connect ${BRIDGES_TORPROJECT_ORG_IP} 443 \
      1> ssl-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log \
      2> ssl-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.err
    ${TESTS_DIR}/http-connect.sh https://${BRIDGES_TORPROJECT_ORG_IP} bridges.torproject.org \
      1> http-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log \
      2> http-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.err
  fi
}

###############################################################################
# TEST: TOR Consensus
###############################################################################

function test_tor_consensus() {
  echo "moria1 128.31.0.39:9131
  tor26 86.59.21.38:80
  dizum 194.109.206.212:80
  Tonga 82.94.251.203:80
  turtles 76.73.17.194:9030
  gabelmoo 212.112.245.170:80
  dannenberg 193.23.244.244:80
  urras 208.83.223.34:443
  maatuska 171.25.193.9:443
  Faravahar 154.35.32.5:80" \
  | shuf \
  | sed 's/:/ /g' \
  | while read AUTH_NAME AUTH_ADDR AUTH_PORT; do
    ${TESTS_DIR}/tor-get-status-vote-current-consensus.sh ${AUTH_ADDR}:${AUTH_PORT}
    [ ! -z "$(find -name 'status*cons*' -size +0 -ls)" ] && return
    # Download failed - try to get more information...
    start_packet_capture \
      -nn \
      -s 0 \
      -p \
      -w tor-authority-${AUTH_ADDR}-icmp.pcap \
      -i any \
      icmp or host ${AUTH_ADDR}
    TOR_AUTHORITY_PCAP_PID=$!
    ping -c 1 ${AUTH_ADDR} > tor-authority-${AUTH_ADDR}-ping.log
    traceroute ${AUTH_ADDR} > tor-authority-${AUTH_ADDR}-traceroute.log
    end_packet_capture ${TOR_AUTHORITY_PCAP_PID}
  done
}

test_tor_consensus

###############################################################################
# TEST: Connect to TOR Guard Nodes
###############################################################################

function test_tor_guard_ssl_connect() {
  [ -z "$(find -name 'status-vote-current-consensus-*')" ] && return
  while read GUARD_ADDR GUARD_PORT; do
    ${TESTS_DIR}/ssl-connect.sh ssl-connect-tor-guard ${GUARD_ADDR} ${GUARD_PORT} \
      2> ssl-connect-tor-guard-${GUARD_ADDR}-${GUARD_PORT}.err \
    | tee ssl-connect-tor-guard-${GUARD_ADDR}-${GUARD_PORT}.log
  done < <( grep --no-filename -B 1 '^s.*\<Guard\>' status-vote-current-consensus-* \
          | grep '^r' \
          | awk '/^r/{if(0 != $NF)print $(NF-2), $(NF-1)}' )
}

#test_tor_guard_ssl_connect
