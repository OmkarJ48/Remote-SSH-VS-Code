# SSH Remote Connection Setup Guide for Raspberry Pi

## Problem Description
VS Code is prompting for a password instead of using the SSH key for authentication with Raspberry Pi at `10.1.6.40`.

## Common Issues & Solutions

### 1. SSH Key File Permissions (Most Common)

SSH is very strict about file permissions. Incorrect permissions will cause authentication to fail silently and fall back to password.

**Fix on Windows:**
```
# In Git Bash or PowerShell
cd ~/.ssh
icacls tl_prototype_key /inheritance:r /grant:r "%USERNAME%:F"
```

**Fix on Linux/Mac:**
```bash
chmod 600 ~/.ssh/tl_prototype_key
chmod 700 ~/.ssh
chmod 644 ~/.ssh/config
```

### 2. SSH Config File Setup

**Location:**
- Windows: `C:\Users\OJoshi\.ssh\config`
- Linux/Mac: `~/.ssh/config`

**Correct Configuration:**
```
Host raspberry-pi
    HostName 10.1.6.40
    User pi
    IdentityFile ~/.ssh/tl_prototype_key
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    AddKeysToAgent yes
```

**Important Points:**
- Use `~` (tilde) instead of Windows absolute paths like `C:\Users\OJoshi\.ssh\...`
- For Windows, you can also use forward slashes: `/c/Users/OJoshi/.ssh/tl_prototype_key`
- Set `IdentitiesOnly yes` to prevent SSH from trying too many keys
- Add `StrictHostKeyChecking accept-new` to auto-accept the host key on first connection

### 3. Verify Key Format

The key might be in PuTTY format (`.ppk`) instead of OpenSSH format.

**Check the key file format:**
```
# Should start with: -----BEGIN OPENSSH PRIVATE KEY-----
# NOT: ---- BEGIN SSH2 ENCRYPTED PRIVATE KEY ----
head -1 ~/.ssh/tl_prototype_key
```

**If it's PuTTY format, convert it:**
- Use PuTTY Key Generator (puttygen.exe)
- Load the `.ppk` file
- Go to Conversions → Export OpenSSH key
- Save as `tl_prototype_key` (no extension)

### 4. Ensure Public Key is on Raspberry Pi

The public key must be added to the Raspberry Pi's `authorized_keys`.

**From your machine:**
```bash
# Copy the public key (generate if needed)
ssh-keygen -y -f ~/.ssh/tl_prototype_key > ~/.ssh/tl_prototype_key.pub

# Copy it to the Pi
ssh-copy-id -i ~/.ssh/tl_prototype_key pi@10.1.6.40
# You'll need to enter the password once
```

**Or manually on the Pi:**
```bash
# SSH into Pi (with password)
ssh pi@10.1.6.40

# Add your public key
mkdir -p ~/.ssh
echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 5. Test SSH Connection from Terminal

**Test basic connectivity:**
```bash
ssh -v pi@10.1.6.40
# -v for verbose output to see where it's failing
```

**Test with specific identity file:**
```bash
ssh -i ~/.ssh/tl_prototype_key -v pi@10.1.6.40
```

**If you want to use a hostname alias:**
```bash
ssh -v raspberry-pi
# Uses the config file entry
```

### 6. VS Code Remote SSH Extension Settings

1. **Install Extension:** Remote - SSH (by Microsoft)
2. **Open SSH Config:**
   - Press `Ctrl+Shift+P`
   - Type "Remote-SSH: Open SSH Configuration File"
   - Edit the config file
3. **Configure Host:**
```
Host raspberry-pi
    HostName 10.1.6.40
    User pi
    IdentityFile ~/.ssh/tl_prototype_key
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    AddKeysToAgent yes
```

4. **Connect:**
   - Click on the Remote Explorer icon (bottom left)
   - Select your host `raspberry-pi`
   - Click "Connect to Host in Current Window"

### 7. SSH Agent Setup

On Windows (PowerShell):
```powershell
# Start SSH Agent
Start-Service ssh-agent

# Add your key
ssh-add $env:USERPROFILE\.ssh\tl_prototype_key
```

On Linux/Mac:
```bash
# Start SSH Agent
eval "$(ssh-agent -s)"

# Add your key
ssh-add ~/.ssh/tl_prototype_key
```

### 8. Debugging Steps

Run these in order to diagnose the issue:

```bash
# 1. Check SSH config syntax
ssh -G raspberry-pi  # Shows how SSH interprets the config

# 2. Verbose connection attempt
ssh -vvv pi@10.1.6.40

# 3. Check key permissions
ls -la ~/.ssh/tl_prototype_key

# 4. Verify key is readable by SSH
ssh -i ~/.ssh/tl_prototype_key -v pi@10.1.6.40 2>&1 | grep -i "permission\|key"

# 5. Check if public key is on the Pi
ssh pi@10.1.6.40 "cat ~/.ssh/authorized_keys"
```

## Summary Checklist

- [ ] SSH key file exists at `~/.ssh/tl_prototype_key`
- [ ] Key file permissions are `600` (Windows: owned by user only)
- [ ] SSH config file exists at `~/.ssh/config`
- [ ] SSH config has correct HostName, User, and IdentityFile
- [ ] Public key is in Raspberry Pi's `~/.ssh/authorized_keys`
- [ ] Can SSH from terminal: `ssh -i ~/.ssh/tl_prototype_key pi@10.1.6.40`
- [ ] VS Code Remote SSH extension is installed
- [ ] VS Code Remote SSH config matches terminal config

## References

- [OpenSSH Manual](https://man.openbsd.org/ssh_config)
- [VS Code Remote SSH Documentation](https://code.visualstudio.com/docs/remote/ssh)
- [SSH Key Permissions Explained](https://superuser.com/questions/215504/permissions-on-ssh-keys)
