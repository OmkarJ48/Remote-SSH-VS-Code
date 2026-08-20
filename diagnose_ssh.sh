#!/bin/bash

# SSH Raspberry Pi Diagnostic Script
# Usage: ./diagnose_ssh.sh [hostname] [user] [key_file]

HOSTNAME=${1:-"10.1.6.40"}
USER=${2:-"pi"}
KEYFILE=${3:-"~/.ssh/tl_prototype_key"}

# Expand tilde
KEYFILE="${KEYFILE/#\~/$HOME}"

echo "=========================================="
echo "SSH Diagnostic Report"
echo "=========================================="
echo "Target: $USER@$HOSTNAME"
echo "Key File: $KEYFILE"
echo ""

# Check 1: Key file exists
echo "[1] Checking if key file exists..."
if [ -f "$KEYFILE" ]; then
    echo "✓ Key file found"
else
    echo "✗ Key file NOT found at: $KEYFILE"
    exit 1
fi

# Check 2: Key file permissions
echo ""
echo "[2] Checking key file permissions..."
PERMS=$(stat -c "%a" "$KEYFILE" 2>/dev/null || stat -f "%OLp" "$KEYFILE" | sed 's/.*\(.\{3\}\)$/\1/')
echo "  Permissions: $PERMS"
if [ "$PERMS" = "600" ] || [ "$PERMS" = "600" ]; then
    echo "  ✓ Permissions correct"
else
    echo "  ✗ WARNING: Permissions should be 600, currently $PERMS"
    echo "    Fix with: chmod 600 \"$KEYFILE\""
fi

# Check 3: SSH folder permissions
echo ""
echo "[3] Checking SSH folder permissions..."
SSH_DIR="$HOME/.ssh"
PERMS=$(stat -c "%a" "$SSH_DIR" 2>/dev/null || stat -f "%OLp" "$SSH_DIR" | sed 's/.*\(.\{3\}\)$/\1/')
echo "  Permissions: $PERMS"
if [ "$PERMS" = "700" ]; then
    echo "  ✓ Permissions correct"
else
    echo "  ✗ WARNING: Permissions should be 700, currently $PERMS"
    echo "    Fix with: chmod 700 \"$SSH_DIR\""
fi

# Check 4: Key format
echo ""
echo "[4] Checking key format..."
FIRST_LINE=$(head -1 "$KEYFILE")
if [[ $FIRST_LINE == *"OPENSSH"* ]]; then
    echo "  ✓ Key is in OpenSSH format"
elif [[ $FIRST_LINE == *"RSA"* ]] || [[ $FIRST_LINE == *"DSA"* ]] || [[ $FIRST_LINE == *"EC"* ]]; then
    echo "  ✓ Key is in OpenSSH format (PEM)"
elif [[ $FIRST_LINE == *"SSH2"* ]]; then
    echo "  ✗ Key is in PuTTY format (needs conversion)"
    echo "    Use PuTTY Key Generator or: ssh-keygen -p -f \"$KEYFILE\""
else
    echo "  ⚠ Unknown key format. First line: $FIRST_LINE"
fi

# Check 5: Public key derived from private key
echo ""
echo "[5] Checking if we can derive public key..."
if ssh-keygen -y -f "$KEYFILE" > /dev/null 2>&1; then
    echo "  ✓ Public key can be derived from private key"
else
    echo "  ✗ Cannot derive public key - key may be corrupted or encrypted"
fi

# Check 6: SSH config file
echo ""
echo "[6] Checking SSH config file..."
SSH_CONFIG="$HOME/.ssh/config"
if [ -f "$SSH_CONFIG" ]; then
    echo "  ✓ Config file found"
    # Look for our host
    if grep -q "10.1.6.40\|raspberry-pi" "$SSH_CONFIG"; then
        echo "  ✓ Host configuration found in config"
    else
        echo "  ⚠ Host configuration not found in config"
    fi
else
    echo "  ⚠ SSH config file not found at: $SSH_CONFIG"
fi

# Check 7: Network connectivity
echo ""
echo "[7] Checking network connectivity..."
if ping -c 1 -W 2 "$HOSTNAME" > /dev/null 2>&1; then
    echo "  ✓ Host is reachable"
else
    echo "  ✗ Host is NOT reachable. Check network connection."
fi

# Check 8: SSH port
echo ""
echo "[8] Checking SSH port..."
if timeout 2 bash -c "</dev/tcp/$HOSTNAME/22" 2>/dev/null; then
    echo "  ✓ SSH port (22) is open"
else
    echo "  ✗ SSH port (22) is NOT open or host unreachable"
fi

# Check 9: Test SSH connection
echo ""
echo "[9] Testing SSH connection (verbose)..."
echo "  Running: ssh -i \"$KEYFILE\" -v $USER@$HOSTNAME"
echo "  ---"
ssh -i "$KEYFILE" -v "$USER@$HOSTNAME" "echo 'Connection successful!'" 2>&1 | head -30
echo "  ---"

echo ""
echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="
