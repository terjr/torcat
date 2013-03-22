# Tor Censorship Analysis Tool
# ============================
#
# Functions
#

# Start a packet capture as a background process.
# We wait for it to start by waiting for 'listening on'.
# Since this is on stderr, we write into a fifo that 'awk' reads.
# Once 'awk' sees 'listening on' it exits to let the caller script continue.
# This is better than a stupid 'sleep' call, yo.
function start_packet_capture() {
  [ -p tcpdump-fifo ] || mkfifo --mode=600 tcpdump-fifo
  tcpdump "$@" 2>tcpdump-fifo &
  awk '{print}/listening on/{exit}' tcpdump-fifo 1>&2
}

# Clean up the packet capture background process.
# If it's still running, then grab the rest of its stderr out of the fifo.
# The call to 'cat' will end once the packet capture process is killed.
# We also sleep for 1 second to let any extra packets get captures before we do the deed.
# Finally, we 'rm' that fifo when we're all done... w0rd
function end_packet_capture() {
  TCPDUMP_PID=$1
  if jobs -l | grep -q "${TCPDUMP_PID}"; then
    (
      cat &
      sleep 1
      kill -INT ${TCPDUMP_PID}
      rm tcpdump-fifo
    ) < tcpdump-fifo 1>&2
  fi
}
