#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))
[ -f "${DIRNAME}/tests/functions.sh" ] && . "${DIRNAME}/tests/functions.sh"

# Set up the path to include 'sbin' directories too...
[[ $PATH =~ (^|:)/usr/local/sbin(:|$) ]] || export PATH=${PATH}:/usr/local/sbin
[[ $PATH =~ (^|:)/usr/sbin(:|$) ]] || export PATH=${PATH}:/usr/sbin
[[ $PATH =~ (^|:)/sbin(:|$) ]] || export PATH=${PATH}:/sbin

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

BRIDGES_TORPROJECT_ORG_IP='38.229.72.19'

# Dig results obtained 2013-03-10 11:16
# www.torproject.org.     900     IN      A       38.229.72.16
# www.torproject.org.     900     IN      A       82.195.75.101
# www.torproject.org.     900     IN      A       86.59.30.40
# www.torproject.org.     900     IN      A       93.95.227.222
# www.torproject.org.     900     IN      A       38.229.72.14
WWW_TORPROJECT_ORG_IP='38.229.72.16 82.195.75.101 86.59.30.40 93.95.227.222 38.229.72.14'

mkdir -v "${DIRNAME}/torcat-${TIMESTAMP}" \
  && cd "${DIRNAME}/torcat-${TIMESTAMP}" \
  || exit $?

TESTS_DIR="${DIRNAME}/tests"

###############################################################################
# Utility Functions
###############################################################################
function log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") $@" | tee -a torcat.log
}

function log_error() {
  log "[error]  " "$@"
}
function log_warning() {
  log "[warning]" "$@"
}
function log_info() {
  log "[info]   " "$@"
}
function log_notice() {
  log "[notice] " "$@"
}
function log_debug() {
  log "[debug] " "$@"
}

###############################################################################
# TEST: Gather host information
###############################################################################

function test_host_information() {

  log_info "TEST: Gathering host information"

  ${TESTS_DIR}/host-information.sh > host-information.log
}

###############################################################################
# TEST: Connect to bridges.torproject.org
###############################################################################

function test_bridges_torproject_org() {

  log_info "TEST: Connection to 'bridges.torproject.org'"

  log_info "    * DNS bridges.torproject.org"
  ${TESTS_DIR}/dns-lookup.sh bridges.torproject.org \
    1> dns-lookup-bridges.torproject.org.log \
    2> dns-lookup-bridges.torproject.org.err
  
  if grep -q "${BRIDGES_TORPROJECT_ORG_IP}" dns-lookup-bridges.torproject.org.log; then
    log_notice " OK - DNS bridges.torproject.org returned known IP address '${BRIDGES_TORPROJECT_ORG_IP}'"
    log_notice "    - Using name 'bridges.torproject.org' for further tests"

    log_info "    * TCP bridges.torproject.org:443"
    ${TESTS_DIR}/tcp-connect.sh bridges.torproject.org 443 \
      1> tcp-connect-bridges.torproject.org-443.log \
      2> tcp-connect-bridges.torproject.org-443.err
  
    log_info "    * SSL bridges.torproject.org:443"
    ${TESTS_DIR}/ssl-connect.sh ssl-connect bridges.torproject.org 443 \
      1> ssl-connect-bridges.torproject.org-443.log \
      2> ssl-connect-bridges.torproject.org-443.err
  
    log_info "    * HTTP https://bridges.torproject.org/"
    ${TESTS_DIR}/http-connect.sh https://bridges.torproject.org \
      1> http-connect-bridges.torproject.org-443.log \
      2> http-connect-bridges.torproject.org-443.err
  else
    log_warning " !! - DNS bridges.torproject.org returned unknown IP address or no IP address at all"
    log_warning "      Using known IP address '${BRIDGES_TORPROJECT_ORG_IP}' for further tests"

    # Cannot lookup bridges.torproject.org correctly.
    # Falling back to known IP address of bridges.torproject.org
    log_info "    * TCP ${BRIDGES_TORPROJECT_ORG_IP}:443"
    ${TESTS_DIR}/tcp-connect.sh ${BRIDGES_TORPROJECT_ORG_IP} 443 \
      1> tcp-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log \
      2> tcp-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.err
  
    log_info "    * SSL ${BRIDGES_TORPROJECT_ORG_IP}:443"
    ${TESTS_DIR}/ssl-connect.sh ssl-connect ${BRIDGES_TORPROJECT_ORG_IP} 443 \
      1> ssl-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log \
      2> ssl-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.err
  
    log_info "    * HTTP https://${BRIDGES_TORPROJECT_ORG_IP}/"
    ${TESTS_DIR}/http-connect.sh https://${BRIDGES_TORPROJECT_ORG_IP} bridges.torproject.org \
      1> http-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log \
      2> http-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.err
  fi
}

###############################################################################
# TEST: Connect to https://www.torproject.org
###############################################################################

function test_www_torproject_org() {

  log_info "TEST: Connection to 'www.torproject.org'"

  log_info "    * DNS www.torproject.org"
  ${TESTS_DIR}/dns-lookup.sh www.torproject.org \
    1> dns-lookup-www.torproject.org.log \
    2> dns-lookup-www.torproject.org.err
  
  if egrep -q $(echo ${WWW_TORPROJECT_ORG_IP} | sed 's/ /|/g') dns-lookup-www.torproject.org.log; then
    log_notice " OK - DNS www.torproject.org returned a known IP address"
    log_notice "    - One of '$(echo ${WWW_TORPROJECT_ORG_IP} | sed 's/ /, /g')'"
    log_notice "    - Using name 'www.torproject.org' for further tests"

    log_info "    * TCP www.torproject.org:443"
    ${TESTS_DIR}/tcp-connect.sh www.torproject.org 443 \
      1> tcp-connect-www.torproject.org-443.log \
      2> tcp-connect-www.torproject.org-443.err
  
    log_info "    * SSL www.torproject.org:443"
    ${TESTS_DIR}/ssl-connect.sh ssl-connect www.torproject.org 443 \
      1> ssl-connect-www.torproject.org-443.log \
      2> ssl-connect-www.torproject.org-443.err
  
    log_info "    * HTTP https://www.torproject.org/"
    ${TESTS_DIR}/http-connect.sh https://www.torproject.org \
      1> http-connect-www.torproject.org-443.log \
      2> http-connect-www.torproject.org-443.err
  else
    log_warning " !! - DNS www.torproject.org returned unknown IP address or no IP address at all"
    log_warning "      Using known IP addresses for further tests"

    # Cannot lookup www.torproject.org correctly.
    # Falling back to known IP address of www.torproject.org
    while read IP; do
      log_info "    * TCP ${IP}:443"
      ${TESTS_DIR}/tcp-connect.sh ${IP} 443 \
        1> tcp-connect-${IP}-443.log \
        2> tcp-connect-${IP}-443.err
      log_info "    * SSL ${IP}:443"
      ${TESTS_DIR}/ssl-connect.sh ssl-connect ${IP} 443 \
        1> ssl-connect-${IP}-443.log \
        2> ssl-connect-${IP}-443.err
      log_info "    * HTTP https://${IP}/"
      ${TESTS_DIR}/http-connect.sh https://${IP} www.torproject.org \
        1> http-connect-${IP}-443.log \
        2> http-connect-${IP}-443.err
    done < <(echo ${WWW_TORPROJECT_ORG_IP} | sed 's/ /\n/g')
  fi
}

###############################################################################
# TEST: TOR Consensus
###############################################################################

function test_tor_consensus() {

  log_info "TEST: Download Tor consensus from directory authorities"
  log_info "    : Trying all known authorities until a successful download"
  log_info "    : If download fails, will ping and traceroute to directory authority server"

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
  | shuf --random-source=/dev/urandom \
  | sed 's/:/ /g' \
  | while read AUTH_NAME AUTH_ADDR AUTH_PORT; do
    log_info "    * Get consensus from authority '${AUTH_NAME}' at '${AUTH_ADDR}:${AUTH_PORT}'"
    ${TESTS_DIR}/tor-get-status-vote-current-consensus.sh ${AUTH_ADDR}:${AUTH_PORT} \
      2> tor-authority-${AUTH_ADDR}-${AUTH_PORT}.err \
    | tee tor-authority-${AUTH_ADDR}-${AUTH_PORT}.log

    if [ ! -z "$(find -name 'status*cons*' -size +0 -ls)" ]; then
       log_notice " OK - Successfully downloaded consensus from '${AUTH_NAME}' at '${AUTH_ADDR}:${AUTH_PORT}'"
       return
    fi

    # Download failed - try to get more information...
    log_warning " !! - Consensus download from '${AUTH_NAME}' at '${AUTH_ADDR}:${AUTH_PORT}' failed."
    log_warning "    - Running ping and traceroute for analysis"
    (
      start_packet_capture \
        -nn \
        -s 0 \
        -p \
        -w tor-authority-${AUTH_ADDR}-icmp.pcap \
        -i any \
        icmp or host ${AUTH_ADDR}
      TOR_AUTHORITY_PCAP_PID=$!
      ping -c 1 ${AUTH_ADDR} > tor-authority-${AUTH_ADDR}-${AUTH_PORT}-ping.log
      traceroute ${AUTH_ADDR} > tor-authority-${AUTH_ADDR}-${AUTH_PORT}-traceroute.log
      end_packet_capture ${TOR_AUTHORITY_PCAP_PID}
    ) 2> tor-authority-${AUTH_ADDR}-${AUTH_PORT}-ping-traceroute.err
  done
}


###############################################################################
# TEST: Connect to TOR Guard Nodes
###############################################################################

function test_tor_guard_ssl_connect() {

  log_notice "TEST: Connecting to Tor guard nodes using SSL"

  CONSENSUS=$(find ./status-vote-current-consensus-* ../status-vote-current-consensus-* -prune -size +500k 2>/dev/null | head -1)
  if [ -z "${CONSENSUS}" ]; then
    log_warning " !! - Could not find a consensus document"
    return
  fi
  while read GUARD_ADDR GUARD_PORT; do
    log_info "    * SSL ${GUARD_ADDR} ${GUARD_PORT}"
    ${TESTS_DIR}/ssl-connect.sh ssl-connect-tor-guard ${GUARD_ADDR} ${GUARD_PORT} \
      1> ssl-connect-tor-guard-${GUARD_ADDR}-${GUARD_PORT}.log \
      2> ssl-connect-tor-guard-${GUARD_ADDR}-${GUARD_PORT}.err
  done < <( grep --no-filename -B 1 '^s.*\<Guard\>' ${CONSENSUS} \
          | grep '^r' \
          | awk '/^r/{if(0 != $NF)print $(NF-2), $(NF-1)}' )
}

###############################################################################
# Main Function
###############################################################################

function main() {
  test_host_information
  test_bridges_torproject_org
  test_www_torproject_org
  test_tor_consensus
  test_tor_guard_ssl_connect
}

main "$@"
