#!/bin/sh
# Keep TCP/32346 reachable on the deployment host.
# 1Panel's firewall chains (1PANEL_BASIC -> 1PANEL_BASIC_AFTER -j DROP) drop
# everything they do not explicitly allow, and they can be regenerated when the
# panel firewall is edited. Both address families must be covered: mobile clients
# prefer IPv6, and a *drop* there costs every connection a full timeout before it
# falls back to IPv4.
set -u
for cmd in iptables ip6tables; do
    command -v "$cmd" >/dev/null 2>&1 || continue
    "$cmd" -n -L 1PANEL_BASIC >/dev/null 2>&1 || continue
    "$cmd" -C 1PANEL_BASIC -p tcp -m tcp --dport 32346 -j ACCEPT 2>/dev/null \
        || "$cmd" -I 1PANEL_BASIC 1 -p tcp -m tcp --dport 32346 -j ACCEPT
done
exit 0