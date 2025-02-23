#!/bin/bash

# SMB Enumeration Script (Authenticated Only)
# Usage:
#   ./smb_enum.sh <TARGET_IP_OR_HOSTNAME> <USERNAME> <PASSWORD>

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
source "$SCRIPT_DIR/util/filesystem.sh"

# Ensure all parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <TARGET_IP_OR_HOSTNAME> <USERNAME> <PASSWORD>"
    exit 1
fi

TARGET="$1"
USERNAME="$2"
PASSWORD="$3"
DIRECTORY='smb_auth_recon'

create_clean_directory $DIRECTORY

# Run all the nmap scripts for smb (Authenticated)
nmap -Pn --script smb-* --script-args smbuser="$USERNAME",smbpass="$PASSWORD" -p 445 -oX $DIRECTORY/nmap_auth.xml $TARGET 2>&1 | tee $DIRECTORY/nmap_auth.txt &

# Attempt to list shares (Authenticated Only)
smbclient -L //$TARGET --user="$USERNAME" --password="$PASSWORD" | tee $DIRECTORY/share_list_auth.txt &
smbmap -H $TARGET -u "$USERNAME" -p "$PASSWORD" | tee -a $DIRECTORY/share_list_auth.txt &

# Run enum4linux tool (Authenticated Only)
enum4linux -a -u "$USERNAME" -p "$PASSWORD" $TARGET | tee -a $DIRECTORY/enum4linux_auth.txt &

# Run rpcclient enumeration (Authenticated Only)
echo "attempting authenticated rpcclient command" | tee $DIRECTORY/rpcclient_auth.txt
rpcclient -U "$USERNAME" --password="$PASSWORD" $TARGET -c "enumdomusers" | tee -a $DIRECTORY/rpcclient_auth.txt &
echo "if this succeeded, authenticated enumeration is possible, and you can probably get an rpc console on the host!" | tee -a $DIRECTORY/rpcclient_auth.txt &

# Wait for all background jobs to complete before exiting
wait

echo "All authenticated SMB enumeration tasks completed."
