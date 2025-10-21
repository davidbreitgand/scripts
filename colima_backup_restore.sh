#!/bin/bash

# Colors for output
RED="[0;31m"
GREEN="[0;32m"
YELLOW="[1;33m"
NC="[0m" # No Color

#Change this to your Colima home directory 
HOME="/Users/davidbr/colima-home" 

# Default paths
DEFAULT_BACKUP_PATH="$HOME/colima-backup.tar.gz"
COLIMA_STATE_DIR="$HOME/.colima"

# Help function
show_help() {
  echo -e "
Usage: $0 [backup|restore] [optional: path_to_backup_file]"
  echo -e "
Commands:"
  echo -e "  backup   Create a backup of Colima state"
  echo -e "  restore  Restore Colima state from a backup"
  echo -e "
Examples:"
  echo -e "  $0 backup"
  echo -e "  $0 backup /path/to/backup.tar.gz"
  echo -e "  $0 restore"
  echo -e "  $0 restore /path/to/backup.tar.gz"
}

# Examples:
# ./colima_backup_restore.sh backup
# ./colima_backup_restore.sh backup /custom/path/backup.tar.gz
# ./colima_backup_restore.sh restore
# ./colima_backup_restore.sh restore /custom/path/backup.tar.gz

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

# Validate command
if [[ "$1" != "backup" && "$1" != "restore" ]]; then
  echo -e "${RED}Error: Invalid command. Use 'backup' or 'restore'.${NC}"
  show_help
  exit 1
fi

# Set backup path
BACKUP_PATH="${2:-$DEFAULT_BACKUP_PATH}"

# Stop Colima before backup or restore
echo -e "${YELLOW}Stopping Colima...${NC}"
colima stop

if [[ "$1" == "backup" ]]; then
  echo -e "${GREEN}Creating backup of Colima state...${NC}"
  tar -czf "$BACKUP_PATH" -C "$HOME" .colima
  echo -e "${GREEN}Backup saved to: $BACKUP_PATH${NC}"

elif [[ "$1" == "restore" ]]; then
  if [ ! -f "$BACKUP_PATH" ]; then
    echo -e "${RED}Error: Backup file not found at $BACKUP_PATH${NC}"
    exit 1
  fi
  echo -e "${GREEN}Restoring Colima state from backup...${NC}"
  rm -rf "$COLIMA_STATE_DIR"
  tar -xzf "$BACKUP_PATH" -C "$HOME"
  echo -e "${GREEN}Restore completed.${NC}"
fi

# Start Colima after operation
echo -e "${YELLOW}Starting Colima...${NC}"
colima start

# Notify user to manually start Colima
echo -e "${YELLOW}Colima has been stopped. Please start it manually if needed using: colima start${NC}"