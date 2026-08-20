# SSH Raspberry Pi Diagnostic Script (Windows PowerShell)
# Usage: .\diagnose_ssh.ps1 -Hostname "10.1.6.40" -User "pi" -KeyFile "~\.ssh\tl_prototype_key"

param(
    [string]$Hostname = "10.1.6.40",
    [string]$User = "pi",
    [string]$KeyFile = "~\.ssh\tl_prototype_key"
)

# Expand tilde to user profile path
$KeyFile = $KeyFile -replace '~', $env:USERPROFILE

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SSH Diagnostic Report (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Target: $User@$Hostname"
Write-Host "Key File: $KeyFile"
Write-Host ""

# Check 1: Key file exists
Write-Host "[1] Checking if key file exists..." -ForegroundColor Yellow
if (Test-Path $KeyFile) {
    Write-Host "✓ Key file found" -ForegroundColor Green
} else {
    Write-Host "✗ Key file NOT found at: $KeyFile" -ForegroundColor Red
    exit 1
}

# Check 2: Key file ownership
Write-Host ""
Write-Host "[2] Checking key file permissions..." -ForegroundColor Yellow
$acl = Get-Acl $KeyFile
$owner = $acl.Owner
$permissions = $acl.Access | Where-Object { $_.IsInherited -eq $false }

Write-Host "  Owner: $owner"
if ($permissions.Count -eq 0) {
    Write-Host "  ✓ No explicit permissions (good - inherited only)" -ForegroundColor Green
} else {
    Write-Host "  ⚠ WARNING: Key has explicit permissions set" -ForegroundColor Yellow
    $permissions | ForEach-Object {
        Write-Host "    - $($_.IdentityReference): $($_.FileSystemRights)" -ForegroundColor Yellow
    }
    Write-Host "  Recommended: Right-click file → Properties → Security → Advanced"
    Write-Host "               Remove all but your user account with Full Control" -ForegroundColor Yellow
}

# Check 3: Key format
Write-Host ""
Write-Host "[3] Checking key format..." -ForegroundColor Yellow
$firstLine = Get-Content $KeyFile | Select-Object -First 1
Write-Host "  First line: $firstLine"
if ($firstLine -like "*OPENSSH*") {
    Write-Host "  ✓ Key is in OpenSSH format" -ForegroundColor Green
} elseif ($firstLine -like "*RSA*" -or $firstLine -like "*DSA*" -or $firstLine -like "*EC*") {
    Write-Host "  ✓ Key is in OpenSSH format (PEM)" -ForegroundColor Green
} elseif ($firstLine -like "*SSH2*") {
    Write-Host "  ✗ Key is in PuTTY format (needs conversion)" -ForegroundColor Red
    Write-Host "  Use PuTTY Key Generator or: ssh-keygen -p -f `"$KeyFile`"" -ForegroundColor Yellow
} else {
    Write-Host "  ⚠ Unknown key format" -ForegroundColor Yellow
}

# Check 4: SSH installation
Write-Host ""
Write-Host "[4] Checking OpenSSH installation..." -ForegroundColor Yellow
$sshPath = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshPath) {
    Write-Host "  ✓ OpenSSH is installed: $($sshPath.Source)" -ForegroundColor Green
} else {
    Write-Host "  ✗ OpenSSH is NOT installed" -ForegroundColor Red
    Write-Host "  Install it or use Git Bash/WSL" -ForegroundColor Yellow
    exit 1
}

# Check 5: SSH config file
Write-Host ""
Write-Host "[5] Checking SSH config file..." -ForegroundColor Yellow
$sshConfigPath = "$env:USERPROFILE\.ssh\config"
if (Test-Path $sshConfigPath) {
    Write-Host "  ✓ Config file found at: $sshConfigPath" -ForegroundColor Green
    $configContent = Get-Content $sshConfigPath -Raw
    if ($configContent -match "10\.1\.6\.40|raspberry-pi") {
        Write-Host "  ✓ Host configuration found in config" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Host configuration not found in config" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ SSH config file not found at: $sshConfigPath" -ForegroundColor Yellow
}

# Check 6: Network connectivity
Write-Host ""
Write-Host "[6] Checking network connectivity..." -ForegroundColor Yellow
$ping = Test-NetConnection -ComputerName $Hostname -WarningAction SilentlyContinue -InformationLevel Quiet
if ($ping) {
    Write-Host "  ✓ Host is reachable" -ForegroundColor Green
} else {
    Write-Host "  ✗ Host is NOT reachable. Check network connection." -ForegroundColor Red
}

# Check 7: SSH port
Write-Host ""
Write-Host "[7] Checking SSH port (22)..." -ForegroundColor Yellow
try {
    $tcpClient = New-Object Net.Sockets.TcpClient
    $tcpClient.BeginConnect($Hostname, 22, $null, $null) | Out-Null
    Start-Sleep -Milliseconds 1000
    if ($tcpClient.Connected) {
        Write-Host "  ✓ SSH port (22) is open" -ForegroundColor Green
        $tcpClient.Close()
    } else {
        Write-Host "  ✗ SSH port (22) is NOT responding" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ SSH port (22) is NOT open or host unreachable" -ForegroundColor Red
}

# Check 8: VS Code Remote SSH Extension
Write-Host ""
Write-Host "[8] Checking VS Code Remote SSH Extension..." -ForegroundColor Yellow
$extensionPath = "$env:USERPROFILE\.vscode\extensions"
if (Test-Path $extensionPath) {
    $remoteExtension = Get-ChildItem $extensionPath -Filter "*remote-ssh*" -Directory
    if ($remoteExtension) {
        Write-Host "  ✓ Remote - SSH extension is installed" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Remote - SSH extension NOT found" -ForegroundColor Yellow
        Write-Host "  Install from VS Code Extension Marketplace" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ VS Code extensions folder not found" -ForegroundColor Yellow
}

# Check 9: Test SSH connection
Write-Host ""
Write-Host "[9] Testing SSH connection..." -ForegroundColor Yellow
Write-Host "  Running: ssh -i `"$KeyFile`" -v $User@$Hostname" -ForegroundColor Gray
Write-Host "  ---"
try {
    # Use Git Bash if available, otherwise use OpenSSH
    $output = ssh -i "$KeyFile" -v "$User@$Hostname" "echo 'Connection successful!'" 2>&1
    $lines = $output -split "`n" | Select-Object -First 30
    $lines | ForEach-Object { Write-Host $_ }
} catch {
    Write-Host "  ✗ SSH connection failed: $_" -ForegroundColor Red
}
Write-Host "  ---"

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Diagnostic Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Fix any permission issues shown above" -ForegroundColor Gray
Write-Host "2. Verify key format is OpenSSH" -ForegroundColor Gray
Write-Host "3. Ensure SSH config is correct" -ForegroundColor Gray
Write-Host "4. Test from PowerShell: ssh -i `"$KeyFile`" $User@$Hostname" -ForegroundColor Gray
Write-Host "5. Then try connecting from VS Code Remote - SSH" -ForegroundColor Gray
