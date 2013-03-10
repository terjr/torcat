# Tor Censorship Analysis Tool
# ============================
#
# Functions
#

function start_packet_capture() {
  tcpdump "$@" &
  sleep 3
}
function end_packet_capture() {
  TCPDUMP_PID=$1
  kill -INT $1
}
