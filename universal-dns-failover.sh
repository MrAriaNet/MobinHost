#!/bin/bash

# -----------------------------------------
# Universal DNS Failover Script
# Author: MrAriaNet
# Description:
#   Checks public DNS servers commonly used in Iran.
#   If all are unreachable, switches to custom DNS servers.
#   Handles systemd-resolved, netplan, NetworkManager and fallback cases.
# -----------------------------------------

# Terminal colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

# List of well-known public DNS resolvers (used in Iran)
PUBLIC_DNS=(
  "8.8.8.8" "8.8.4.4"             # Google
  "4.2.2.1" "4.2.2.4"             # Level3
  "1.1.1.1" "1.0.0.1"             # Cloudflare
  "9.9.9.9" "149.112.112.112"     # Quad9
  "208.67.222.222" "208.67.220.220" # OpenDNS
)

# Your own fallback DNS servers
CUSTOM_DNS=("87.107.110.109" "87.107.110.110")

# A simple domain used to verify DNS functionality
TEST_DOMAIN="google.com"

# -------------------------------
# Function: test_dns
# Description: Uses dig to test DNS resolution via a specific resolver
# -------------------------------
test_dns() {
  dig @"$1" "$TEST_DOMAIN" +time=2 +tries=1 +short > /dev/null 2>&1
  return $?
}

# -------------------------------
# Function: reset_resolv_conf
# Description: Cleanly recreates /etc/resolv.conf with your custom DNS servers
# -------------------------------
reset_resolv_conf() {
  echo -e "${YELLOW}Rebuilding /etc/resolv.conf...${NC}"
  rm -f /etc/resolv.conf
  {
    echo "# Managed by universal-dns-failover.sh"
    for dns in "${CUSTOM_DNS[@]}"; do
      echo "nameserver $dns"
    done
  } > /etc/resolv.conf
}

# -------------------------------
# Function: disable_systemd_resolved
# Description: Turns off systemd-resolved and removes its resolv.conf link
# -------------------------------
disable_systemd_resolved() {
  echo -e "${YELLOW}Disabling systemd-resolved...${NC}"
  systemctl disable --now systemd-resolved 2>/dev/null
  rm -f /etc/resolv.conf
}

# -------------------------------
# Function: configure_networkmanager
# Description: Updates active NetworkManager connections with custom DNS
# -------------------------------
configure_networkmanager() {
  echo -e "${YELLOW}Applying DNS via NetworkManager...${NC}"
  for con in $(nmcli -t -f NAME connection show); do
    nmcli connection modify "$con" ipv4.ignore-auto-dns yes
    nmcli connection modify "$con" ipv4.dns "${CUSTOM_DNS[*]}"
    nmcli connection up "$con" > /dev/null 2>&1
  done
}

# -------------------------------
# Function: apply_custom_dns
# Description: Detects DNS system in use and applies your fallback DNS
# -------------------------------
apply_custom_dns() {
  echo -e "${YELLOW}Switching to fallback DNS configuration...${NC}"

  if systemctl is-active --quiet systemd-resolved; then
    disable_systemd_resolved
    reset_resolv_conf

  elif [ -d /etc/netplan ]; then
    echo -e "${YELLOW}Netplan detected. Forcing DNS manually...${NC}"
    disable_systemd_resolved
    reset_resolv_conf

  elif command -v nmcli &>/dev/null && nmcli general status &>/dev/null; then
    configure_networkmanager
    reset_resolv_conf

  else
    reset_resolv_conf
  fi
}

# -------------------------------
# Main Execution Starts Here
# -------------------------------

echo -e "${YELLOW}Step 1: Checking public DNS resolvers...${NC}"
for dns in "${PUBLIC_DNS[@]}"; do
  if test_dns "$dns"; then
    echo -e "${GREEN}✔ Public DNS $dns is working. No changes needed.${NC}"
    exit 0
  else
    echo -e "${YELLOW}... $dns did not respond.${NC}"
  fi
done

echo -e "${RED}✖ All public DNS resolvers failed.${NC}"
apply_custom_dns

echo -e "${YELLOW}Step 2: Testing fallback DNS servers...${NC}"
for dns in "${CUSTOM_DNS[@]}"; do
  if test_dns "$dns"; then
    echo -e "${GREEN}✔ Fallback DNS $dns is working and now active.${NC}"
    exit 0
  else
    echo -e "${YELLOW}... Fallback DNS $dns is not responding.${NC}"
  fi
done

echo -e "${RED}✖ None of the fallback DNS servers responded.${NC}"
echo -e "${RED}Please contact your server's network administrator or support team.${NC}"
exit 2
