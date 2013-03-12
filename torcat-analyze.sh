#!/bin/bash
DIRNAME=$(dirname $(readlink --canonicalize $0))

TORCAT_DIR=$1

BRIDGES_TORPROJECT_ORG_IP='38.229.72.19'
SSL_GUARD_CONNECT_MIN_PERCENTAGE=100

if [ -z "${TORCAT_DIR}" -o ! -d "${TORCAT_DIR}" ]; then
  echo "$0 <torcat-output-directory>"
  echo ""
  echo "Example:"
  echo ""
  echo "$0 torcat-20130310-012345"
  echo ""
  exit 0
fi 1>&2

echo ""
echo "[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]"
echo "[[[[[[ Tor Censorship Analysis Tool ]]]]]]"
echo "[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]"
echo ""

# Check resolution of bridges.torproject.org...
echo "[TEST] Checking what 'bridges.torproject.org' resolve to"
echo -n "       "
grep '^bridges.torproject.org' ${TORCAT_DIR}/dns-lookup-bridges.torproject.org.log
if grep -q '^bridges.torproject.org.*38\.229\.72' ${TORCAT_DIR}/dns-lookup-bridges.torproject.org.log; then
  echo "[ OK ] Looks like 'bridges.torproject.org' resolves correctly"
else
  echo "[FAIL] Looks like 'bridges.torproject.org' did not resolve correctly"
  echo "       The DNS response is probably being spoofed"
fi
echo ""

# Check if able to connect to bridges.torproject.org...
if grep -q 'obfs2' ${TORCAT_DIR}/http-connect-bridges.torproject.org-443.log; then
  echo "[ OK ] Looks like you can connect to https://bridges.torproject.org"
  echo "       You could probably browse there and request a hidden bridge node"
  echo ""
fi

# Check if able to connect to bridges.torproject.org via IP address...
if [ -f "${TORCAT_DIR}/http-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log" ] \
&& grep -q 'obfs2' ${TORCAT_DIR}/http-connect-${BRIDGES_TORPROJECT_ORG_IP}-443.log; then
  echo "[ OK ] Looks like you can connect to https://bridges.torproject.org via IP address"
  echo "       You could add the IP address to your hosts file before connecting with a browser"
  echo "       Add the following to either /etc/hosts (on Linux, BSD, Mac OSX) or"
  echo "       C:\\windows\\system32\\drivers\\etc\\hosts (on Windows)."
  echo ""
  echo "${BRIDGES_TORPROJECT_ORG_IP} bridges.torproject.org"
  echo ""
  echo "       You could could then browse there and request a hidden bridge node"
  echo ""
fi

# Check if received the consensus...
for a in ${TORCAT_DIR}/status-vote-current-consensus-*; do
  echo "[TEST] Checking consensus $a"
  grep -q -e '^valid-after' -e '^fresh-until' -e '^valid-until' $a \
  && echo "[ OK ] Found validity time range records. Looking like a good consensus" \
  || echo "[FAIL] No validity time range records found. Looks like consensus failed to download"
  grep -q '^directory-footer$' $a \
  && echo "[ OK ] Found 'directory-footer' record, so looks like this has a complete consensus" \
  || echo "[FAIL] Record 'directory-footer' not found! Looks like this is an incomplete consensus"
done
echo ""

# Scan for successful SSL connections to the guard nodes...
echo "[TEST] Checking how many successful SSL connections could be made to the guard nodes"
GUARD_NODE_COUNT=$(ls ${TORCAT_DIR}/ssl-connect-tor-guard-*.log | wc -l)
echo "       Number of attempts: ${GUARD_NODE_COUNT}"
GUARD_NODE_CONNECT_COUNT=$(grep --no-filename '^SSL-Session:' ${TORCAT_DIR}/ssl-connect-tor-guard-*.log | wc -l)
echo "       Number of connects: ${GUARD_NODE_CONNECT_COUNT}"
awk 'BEGIN{printf "       Number of connects: %3d%%\n", (100*ARGV[1])/ARGV[2]}' ${GUARD_NODE_CONNECT_COUNT} ${GUARD_NODE_COUNT}

if [ $(((100*${GUARD_NODE_CONNECT_COUNT})/${GUARD_NODE_COUNT})) -lt ${SSL_GUARD_CONNECT_MIN_PERCENTAGE} ]; then
  echo "[WARN] You can connect to less that ${SSL_GUARD_CONNECT_MIN_PERCENTAGE}% of the guard nodes"
  echo "       Many guard nodes are blocked"
  echo "       You should probably try to connect to a hidden bridge"
  echo "       Use https://bridges.torproject.org to get a hidden bridge"
  echo "       If you can't get there, then use the IP address of bridges.torproject.org instead"
  echo "       Add '${BRIDGES_TORPROJECT_ORG_IP} bridges.torproject.org' to your hosts file"
  echo "       Then, browse to https://bridges.torproject.org"
fi
