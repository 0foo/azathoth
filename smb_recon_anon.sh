#!/bin/bash

# SMB Enumeration and Recursive Download Script
# Usage:
#   ./smb_recon_anon.sh <TARGET_IP_OR_HOSTNAME>


if [ -z "$1" ]; then
    echo "Usage: $0 <TARGET_IP_OR_HOSTNAME>"
    exit 1
fi

TARGET=$1

## Set logger
LOGDIR=$(basename "$0")
DATE=$(date +'%Y%m%d_%H%M%S')
LOGFILE="./$LOGDIR/$DATE/scan.log"
mkdir -p "./$LOGDIR/$DATE"
exec > >(tee -a "$LOGFILE") 2>&1

# Run all the nmap scripts for smb 
nmap -Pn --script smb-* -p 445 -oX "./$LOGDIR/$DATE/nmap_results.xml" $TARGET 2>&1

# Attempt to list anonymous shares 
smbclient -L //$TARGET --user="" --password="" -N
smbmap -H $TARGET -u "" -p "" 

# Run enum4linux tool
enum4linux -a $TARGET 

# Run rpcclient enumeration
echo "attempting anonymous rpcclient command"
rpcclient -U "" --password="" $TARGET -c "enumdomusers" 
echo "if this succeeded and you see output you most likely can open an rpcclient on the host"

echo "All SMB enumeration tasks completed."
echo "[+] Log file saved to: $LOGFILE"


