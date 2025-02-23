#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
source "$SCRIPT_DIR/util/filesystem.sh"
PWD=$(pwd)

# Check for required arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <HOST> <USER> <PASSWORD>"
    exit 1
fi

# Get arguments
HOST="$1"
USER="$2"
PASS="$3"

# Configuration
SMB_USER_DIR="$PWD/smb_sync/$USER"
OUTPUT_CSV="$SMB_USER_DIR/smb_shares.csv"
SMB_RESULTS_DIR="$SMB_USER_DIR/results"
OUTPUT_CSV="$SMB_USER_DIR/smb_shares.csv"

# Ensure the sync directory exists
create_clean_directory "$SMB_USER_DIR"

# Run smbmap and output to CSV
smbmap --csv "$OUTPUT_CSV" -H "$HOST" --user "$USER" --pass "$PASS"

# Create results directory and move into it
mkdir -p "$SMB_RESULTS_DIR" && cd "$SMB_RESULTS_DIR"

# Extract share names and attempt sync
tail -n +2 "$OUTPUT_CSV" | cut -d',' -f2 | while read -r SHARE; do
    # SHARE=$(echo "$SHARE" | sed 's/^ *//;s/ *$//')  # Trim spaces
    echo "Syncing share: ${SHARE}."
    smbclient "//${HOST}/${SHARE}" -U "${USER}%${PASS}" -c "prompt OFF; recurse ON; mget *" 2>/dev/null
done

echo "[*] SMB Sync complete."

