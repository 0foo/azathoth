#!/bin/bash

# SMB Enumeration and Recursive Download Script
# Usage:
#   ./smb_enum.sh <TARGET_IP_OR_HOSTNAME>

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
source "$SCRIPT_DIR/util/filesystem.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <TARGET_IP_OR_HOSTNAME>"
    exit 1
fi

TARGET=$1
create_clean_directory "smb_anon_recon"

# Run all the nmap scripts for smb 
nmap -Pn --script smb-* -p 445 -oX ./smb_results/nmap_anon.xml $TARGET 2>&1 | tee smb_results/nmap_anon.txt &

# Attempt to list anonymous shares 
smbclient -L //$TARGET --user="" --password="" -N | tee smb_results/share_list_anon.txt &
smbmap -H $TARGET -u "" -p "" | tee -a smb_results/share_list_anon.txt &

# Run enum4linux tool
enum4linux -a $TARGET | tee -a smb_results/enum4linux_anon.txt &

# Run rpcclient enumeration
echo "attempting anonymous rpcclient command" | tee smb_results/rpcclient_anon.txt
rpcclient -U "" --password="" $TARGET -c "enumdomusers" | tee -a smb_results/rpcclient_anon.txt &
echo "if this succeeded and you see output you most likely can open an rpcclient on the host" | tee -a smb_results/rpcclient_anon.txt &

# Wait for all background jobs to complete before exiting
wait

echo "All SMB enumeration tasks completed."



