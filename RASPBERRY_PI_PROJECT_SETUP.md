# Raspberry Pi Remote SSH Project Setup Guide

## Common Issue: Wrong Project Root Directory

When using VS Code Remote SSH to develop on Raspberry Pi, the project must be in the correct home directory.

### The Problem
```
❌ WRONG:  /root/SSH/Documents/OJoshi/Rnd_Camera
✅ RIGHT:  /home/pi/Documents/OJoshi/Rnd_Camera
```

**Why it matters:**
- `/root` is the root user's home directory
- `/home/pi` is the Pi user's home directory
- SSH connects as the `pi` user (not root)
- VS Code Remote SSH extensions and tools expect files in the Pi user's home

### The Fix (Step-by-Step)

**Step 1: Check your current directory**
```bash
pwd
```
Shows you where you currently are.

**Step 2: List files to see what's there**
```bash
ls
```

**Step 3: Create the correct directory structure (if needed)**
```bash
mkdir -p /home/pi/Documents/OJoshi
```
The `-p` flag creates parent directories if they don't exist.

**Step 4: Move your project to the correct location**
```bash
mv /root/SSH/Documents/OJoshi/Rnd\ Camera /home/pi/Documents/OJoshi/
```
This moves the entire project folder from the wrong location to the right one.

**Step 5: Verify the move was successful**
```bash
ls /home/pi/Documents/OJoshi/
# Should show: Rnd Camera
```

**Step 6: Open the project from the correct path**
```bash
code /home/pi/Documents/OJoshi/Rnd\ Camera
```
Or in VS Code Remote SSH, use File → Open Folder and browse to `/home/pi/Documents/OJoshi/Rnd Camera`

### Why This Matters for SSH

When you SSH into the Raspberry Pi as user `pi`:
- Your home directory is `/home/pi`
- Your default working directory is `/home/pi`
- Terminal commands and scripts expect relative paths from here
- VS Code Server installs and stores data in `~/.vscode-server`

If your project is in `/root/SSH/...`, it's:
- Outside the `pi` user's home directory
- Requires elevated permissions to access
- Can cause permission issues with VS Code extensions
- Not in the expected location for the `pi` user

### Directory Structure Best Practice

```
/home/pi/
├── Desktop/
├── Documents/
│   ├── Projects/
│   │   ├── Rnd_Camera/
│   │   ├── WebApp/
│   │   └── ...
│   └── OJoshi/
│       └── Rnd_Camera/
├── Downloads/
└── .vscode-server/  (Created automatically by VS Code)
```

### Quick Checklist

- [ ] Project is in `/home/pi/Documents/...` (not `/root/...`)
- [ ] Can SSH into Pi: `ssh pi@10.1.6.40`
- [ ] Can navigate to project: `cd /home/pi/Documents/OJoshi/Rnd_Camera`
- [ ] Project files are accessible: `ls -la`
- [ ] Open in VS Code: `code /home/pi/Documents/OJoshi/Rnd_Camera`
- [ ] VS Code shows correct path in Explorer (top of file tree)

### Troubleshooting

**"Permission denied" errors:**
```bash
# Check ownership
ls -la /home/pi/Documents/OJoshi/
# Should show: pi  pi (owner and group)

# Fix ownership if needed
sudo chown -R pi:pi /home/pi/Documents/OJoshi/
```

**"No such file or directory":**
```bash
# Verify the full path exists
ls -la /home/pi/Documents/OJoshi/Rnd\ Camera
# If not, create it and move files there
```

**VS Code can't find the project:**
1. Close all VS Code windows
2. SSH into Pi: `ssh pi@10.1.6.40`
3. Verify path: `ls /home/pi/Documents/OJoshi/Rnd_Camera`
4. Open from terminal: `code /home/pi/Documents/OJoshi/Rnd_Camera`

## Related Guides

- [SSH_SETUP_GUIDE.md](./SSH_SETUP_GUIDE.md) - SSH authentication setup
- [SSH_QUICK_REFERENCE.md](./SSH_QUICK_REFERENCE.md) - Quick commands reference
