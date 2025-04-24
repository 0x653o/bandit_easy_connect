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

# Set variables
BANDIT_NUM="$1"
PASSWORD="$2"
REMOTE_HOST="bandit.labs.overthewire.org"
REMOTE_USER="bandit$BANDIT_NUM"
PORT="2220"

# Display information
echo "Bandit number = $BANDIT_NUM"
echo "Password = $PASSWORD"

# Check if expect is installed
if ! command -v expect >/dev/null 2>&1; then
  echo "expect is not installed. Attempting to install..."

  # Check package manager and install expect
  if command -v apt >/dev/null 2>&1; then
    # Ubuntu
    sudo apt update
    sudo apt install -y expect
  elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL
    sudo yum install -y expect
  elif command -v brew >/dev/null 2>&1; then
    # macOS (Homebrew installed)
    brew install expect
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
      # Install expect
      brew install expect
    else
      echo "Homebrew installation canceled. Please install expect manually."
      show_usage
      exit 1
    fi
  fi

  # Verify installation
  if ! command -v expect >/dev/null 2>&1; then
    echo "Failed to install expect. Please install it manually."
    show_usage
    exit 1
  fi
  echo "expect has been successfully installed."
fi

# SSH connection using expect
/usr/bin/expect <<EOF
  spawn ssh -p $PORT $REMOTE_USER@$REMOTE_HOST
  expect {
    "Are you sure you want to continue connecting (yes/no/[fingerprint])?" {
      send "yes\r"
      expect {
        "$REMOTE_USER@$REMOTE_HOST's password:" {
          send "$PASSWORD\r"
          expect {
            "$REMOTE_USER@*" {
              # Successfully logged in
            }
            "Permission denied" {
              puts "Error: Incorrect password."
              exit 1
            }
            eof {
              puts "Error: SSH connection failed (incorrect password or server issue)."
              exit 1
            }
          }
        }
        eof {
          puts "Error: SSH connection failed (unable to connect to server)."
          exit 1
        }
      }
    }
    "$REMOTE_USER@$REMOTE_HOST's password:" {
      send "$PASSWORD\r"
      expect {
        "$REMOTE_USER@*" {
          # Successfully logged in
        }
        "Permission denied" {
          puts "Error: Incorrect password."
          exit 1
        }
        eof {
          puts "Error: SSH connection failed (incorrect password or server issue)."
          exit 1
        }
      }
    }
    "Connection refused" {
      puts "Error: Unable to connect to server (check port $PORT or host $REMOTE_HOST)."
      exit 1
    }
    "Could not resolve hostname" {
      puts "Error: Could not resolve hostname ($REMOTE_HOST). Check DNS or network."
      exit 1
    }
    eof {
      puts "Error: SSH connection failed (unknown error)."
      exit 1
    }
  }
  interact
EOF

# Check expect exit status
if [ $? -ne 0 ]; then
  echo "SSH connection failed. Please check the error message above."
  show_usage
  exit 1
fi

# Set script file permissions
chmod 600 "$0"
echo "Script file permissions set to 600."
