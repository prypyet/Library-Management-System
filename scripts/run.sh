#!/bin/bash
set -e
cd "$(dirname "$0")/.."
chmod +x public/cgi-bin/*.sh
command -v busybox >/dev/null || { echo "Install BusyBox: sudo apt install busybox"; exit 1; }
echo "Dashboard running on port 8080. Keep this terminal open."
busybox httpd -f -p 0.0.0.0:8080 -h "$PWD/public"
