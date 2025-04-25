#!/bin/bash

# Display usage instructions
show_usage() {
  echo "Usage:"
  echo "  1. Make the script executable:"
  echo "     chmod +x bandit.sh"
  echo "  2. Run the script:"
  echo "     ./bandit.sh <bandit_number> <password>"
  echo "  Example: ./bandit.sh 0 bandit"
  echo "  - <bandit_number>: Bandit level number (e.g., 0, 1, 2, ...)"
  echo "  - <password>: Password for the corresponding bandit level"
  echo "  Note: The password is passed as a command-line argument and may be stored in shell history."
}

# Check input arguments
if [ $# -ne 2 ]; then
  echo "Error: Bandit number and password are required."
  show_usage
  exit 1
fi

# Validate bandit number (must be a non-negative integer)
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Error: Bandit number must be a non-negative integer."
  show_usage
  exit 1
fi

# Set variables
BANDIT_NUM="$1"
PASSWORD="$2"
REMOTE_HOST="bandit.labs.overthewire.org"
REMOTE_USER="bandit$BANDIT_NUM"
PORT="2220"
PASSWORD_LOG="bandit_passwords.txt"
NEXT_BANDIT=$((BANDIT_NUM + 1))
LOG_FILE=".bandit_script.log"

# Display information
echo "Bandit number = $BANDIT_NUM"
echo "Password = $PASSWORD"

# Check if sshpass is installed
if ! command -v sshpass >/dev/null 2>&1; then
  echo "sshpass is not installed. Attempting to install..."

  # Check package manager and install sshpass
  if command -v apt >/dev/null 2>&1; then
    # Ubuntu
    sudo apt update
    sudo apt install -y sshpass
  elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL
    sudo yum install -y sshpass
  elif command -v brew >/dev/null 2>&1; then
    # macOS (Homebrew installed)
    brew install sshpass
  else
    # macOS without Homebrew or other OS
    echo "Homebrew is not installed."
    read -p "Would you like to install Homebrew on macOS? (y/n): " install_brew
    if [ "$install_brew" = "y" ] || [ "$install_brew" = "Y" ]; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Set up Homebrew environment (add to PATH)
      if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
      # Install sshpass
      brew install sshpass
    else
      echo "Homebrew installation canceled. Please install sshpass manually."
      show_usage
      exit 1
    fi
  fi

  # Verify installation
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "Failed to install sshpass. Please install it manually."
    show_usage
    exit 1
  fi
  echo "sshpass has been successfully installed."
fi

# Function to log or update password
check_and_update_password() {
  local log_entry="bandit$BANDIT_NUM => bandit$NEXT_BANDIT"
  local temp_file="temp_passwords.txt"

  if [ -f "$PASSWORD_LOG" ]; then
    # Check if the entry exists
    if grep -q "^$log_entry" "$PASSWORD_LOG"; then
      # Replace the existing entry with the new password
      sed "s/^$log_entry .*/$log_entry $PASSWORD/" "$PASSWORD_LOG" > "$temp_file"
      mv "$temp_file" "$PASSWORD_LOG"
      echo "Updated password for $log_entry in $PASSWORD_LOG" >> "$LOG_FILE"
    else
      # Append new entry
      echo "$log_entry $PASSWORD" >> "$PASSWORD_LOG"
      echo "Logged password to $PASSWORD_LOG" >> "$LOG_FILE"
    fi
  else
    # Create new log file and append
    echo "$log_entry $PASSWORD" >> "$PASSWORD_LOG"
    echo "Created and logged password to $PASSWORD_LOG" >> "$LOG_FILE"
  fi
  # Set permissions for the log file
  chmod 600 "$PASSWORD_LOG" 2>/dev/null
}

# Attempt SSH connection using sshpass
echo "Connecting to $REMOTE_USER@$REMOTE_HOST on port $PORT..."
SSHPASS="$PASSWORD" sshpass -e ssh -p "$PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$REMOTE_USER@$REMOTE_HOST" 2>>"$LOG_FILE"
SSH_EXIT_STATUS=$?

# Check SSH connection status
if [ $SSH_EXIT_STATUS -ne 0 ]; then
  echo "Error: SSH connection failed. Possible reasons:"
  echo "  - Incorrect password"
  echo "  - Server is unreachable (check host $REMOTE_HOST and port $PORT)"
  echo "  - Network issues"
  echo "Check $LOG_FILE for details."
  show_usage
  exit 1
fi

# Log or update password in the background
(
  check_and_update_password
  # Set script file permissions to preserve executable bit
  chmod 700 "$0" 2>/dev/null
  echo "Script file permissions set to 700." >> "$LOG_FILE"
) &

# Exit successfully
exit 0
