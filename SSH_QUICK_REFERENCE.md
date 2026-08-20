# SSH Quick Reference for Raspberry Pi

## One-Liner Quick Setup

### Windows (PowerShell):
```powershell
# 1. Generate key (if needed)
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\tl_prototype_key -N ""

# 2. Fix permissions
icacls $env:USERPROFILE\.ssh\tl_prototype_key /inheritance:r /grant:r "%USERNAME%:F"

# 3. Copy key to Pi (first time, use password)
ssh-copy-id -i $env:USERPROFILE\.ssh\tl_prototype_key pi@10.1.6.40

# 4. Test connection
ssh -i $env:USERPROFILE\.ssh\tl_prototype_key pi@10.1.6.40
```

### Linux/Mac:
```bash
# 1. Generate key (if needed)
ssh-keygen -t ed25519 -f ~/.ssh/tl_prototype_key -N ""

# 2. Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/tl_prototype_key
chmod 644 ~/.ssh/authorized_keys

# 3. Copy key to Pi
ssh-copy-id -i ~/.ssh/tl_prototype_key pi@10.1.6.40

# 4. Test connection
ssh -i ~/.ssh/tl_prototype_key pi@10.1.6.40
```

## SSH Config for VS Code

**File Location:**
- Windows: `C:\Users\OJoshi\.ssh\config`
- Linux/Mac: `~/.ssh/config`

**Minimal Config:**
```
Host raspberry-pi
    HostName 10.1.6.40
    User pi
    IdentityFile ~/.ssh/tl_prototype_key
    IdentitiesOnly yes
```

**Full Config (Recommended):**
```
Host raspberry-pi
    HostName 10.1.6.40
    User pi
    Port 22
    IdentityFile ~/.ssh/tl_prototype_key
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UserKnownHostsFile ~/.ssh/known_hosts
    AddKeysToAgent yes
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 600
```

## Common Commands

| Task | Command |
|------|---------|
| **Test SSH** | `ssh -i ~/.ssh/tl_prototype_key pi@10.1.6.40` |
| **Test with verbose** | `ssh -vvv -i ~/.ssh/tl_prototype_key pi@10.1.6.40` |
| **Copy files to Pi** | `scp -i ~/.ssh/tl_prototype_key file.txt pi@10.1.6.40:/home/pi/` |
| **Copy files from Pi** | `scp -i ~/.ssh/tl_prototype_key pi@10.1.6.40:/home/pi/file.txt .` |
| **SSH tunnel** | `ssh -i ~/.ssh/tl_prototype_key -L 3000:localhost:3000 pi@10.1.6.40` |
| **Generate public key** | `ssh-keygen -y -f ~/.ssh/tl_prototype_key > ~/.ssh/tl_prototype_key.pub` |

## Troubleshooting Checklist

- [ ] Key file exists and is readable
- [ ] Key permissions: `600` (or Windows user-only)
- [ ] SSH folder permissions: `700`
- [ ] Key format: OpenSSH (not PuTTY)
- [ ] Public key is in Raspberry Pi's `~/.ssh/authorized_keys`
- [ ] Can ping the Raspberry Pi: `ping 10.1.6.40`
- [ ] SSH port is open: `ssh -G raspberry-pi` (shows config)
- [ ] No passphrase on key (or SSH agent is running)
- [ ] VS Code Remote SSH extension is installed
- [ ] VS Code SSH config is correct

## Key Generation Options

### Ed25519 (Recommended - Modern & Secure)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/tl_prototype_key -N ""
```

### RSA 4096-bit (Good - Widely Compatible)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/tl_prototype_key -N ""
```

### From Existing Key - Convert Format
```bash
# PuTTY to OpenSSH
ssh-keygen -p -f ~/.ssh/tl_prototype_key -m pem -N ""
```

## If Still Getting Password Prompt

1. **Check SSH is trying the key:**
   ```bash
   ssh -vvv pi@10.1.6.40  # Look for "Offering public key" or "key_load_private"
   ```

2. **Force specific key:**
   ```bash
   ssh -i ~/.ssh/tl_prototype_key pi@10.1.6.40
   ```

3. **Disable agent if it's interfering:**
   ```bash
   ssh -o IdentitiesOnly=yes -i ~/.ssh/tl_prototype_key pi@10.1.6.40
   ```

4. **Start SSH agent and add key:**
   ```bash
   # Linux/Mac
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/tl_prototype_key
   
   # Windows (if available)
   Start-Service ssh-agent
   ssh-add $env:USERPROFILE\.ssh\tl_prototype_key
   ```

## VS Code Connection Workflow

1. **Install Extension:** Remote - SSH (ms-vscode-remote.remote-ssh)
2. **Setup SSH Config:** Edit `~/.ssh/config`
3. **Test Terminal:** `ssh raspberry-pi` should work
4. **VS Code:** Open Remote Explorer → Select host → Connect

## Important Files

| Path | Purpose | Permissions |
|------|---------|-------------|
| `~/.ssh/` | SSH directory | `700` |
| `~/.ssh/tl_prototype_key` | Private key | `600` |
| `~/.ssh/tl_prototype_key.pub` | Public key | `644` |
| `~/.ssh/config` | SSH config | `644` |
| `~/.ssh/known_hosts` | Known hosts | `644` |

## On Raspberry Pi

**Login and setup (first time):**
```bash
# On the Pi, via password login first
ssh pi@10.1.6.40

# Then on the Pi:
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key (paste content)
echo "your-public-key-here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Disable password auth (optional, after confirming key works)
# sudo nano /etc/ssh/sshd_config
# Change: PasswordAuthentication no
# sudo systemctl restart ssh
```
