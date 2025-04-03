# setup.ps1
Write-Host "Verifying base dependencies..."
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python not found. Install Python or Anaconda manually."
    exit 1
}

# Check for Anaconda 3 and offer install
$condaPath = "$env:USERPROFILE\Anaconda3\Scripts"
if (-not (Test-Path "$condaPath\conda.exe")) {
    Write-Host "Anaconda 3 not detected."
    $installConda = Read-Host "Install Anaconda 3? (Y/N)"
    if ($installConda -eq 'Y') {
        Write-Host "Installing Anaconda 3 via winget..."
        winget install -e --id Anaconda.Anaconda3 --silent
        if ($?) {
            Write-Host "Anaconda 3 installed. Restart PowerShell if needed."
        } else {
            Write-Error "Failed to install Anaconda 3. Install manually and rerun."
            exit 1
        }
    } else {
        Write-Host "Skipping Anaconda 3 installation."
    }
}

# Set up Conda environment with yt-dlp and ffmpeg (optional)
$envName = "$env:USERNAME-ML"  # e.g., gtai8-ML
if (Test-Path "$condaPath\conda.exe") {
    Write-Host "Setting up Conda environment: $envName"
    & "$condaPath\conda.exe" env create -n $envName python=3.11 --quiet 2>$null
    if ($?) {
        Write-Host "Environment $envName created."
    } else {
        Write-Host "Environment $envName may already exist."
    }
    & "$condaPath\conda.exe" install -n $envName yt-dlp ffmpeg -y --quiet
    if ($?) {
        Write-Host "yt-dlp and ffmpeg installed in $envName."
    } else {
        Write-Warning "Failed to install dependencies in $envName. Ensure pip install yt-dlp ffmpeg-python manually if needed."
    }
} else {
    Write-Host "Installing yt-dlp via pip (no Anaconda detected)..."
    python -m pip install yt-dlp ffmpeg-python --quiet
    if ($?) {
        Write-Host "yt-dlp and ffmpeg-python installed."
    } else {
        Write-Error "Failed to install yt-dlp. Run 'pip install yt-dlp ffmpeg-python' manually."
        exit 1
    }
}

# Prompt to add Anaconda 3 to PATH
$addConda = Read-Host "Add Anaconda 3 to your user PATH? (Y/N)"
if ($addConda -eq 'Y' -and (Test-Path $condaPath)) {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$condaPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$condaPath", "User")
        Write-Host "Anaconda 3 added to user PATH. Restart PowerShell to apply."
    } else {
        Write-Host "Anaconda 3 already in PATH."
    }
} else {
    Write-Host "Skipped adding Anaconda 3 to PATH."
}

# Prompt for alias with warning
Write-Warning "Note: I don’t recommend adding aliases in an Administrator shell to avoid profile conflicts."
$addAlias = Read-Host "Add 'ytsh' alias to your PowerShell profile? (Y/N)"
if ($addAlias -eq 'Y') {
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force
    }
    $scriptPath = "$PWD\ytsh.py"
    Add-Content -Path $PROFILE -Value "Set-Alias -Name ytsh -Value 'python $scriptPath'"
    Write-Host "Alias 'ytsh' added. Restart PowerShell or run '. $PROFILE' to apply."
    Write-Host "Run 'ytsh' to start downloading."
} else {
    Write-Host "Alias skipped. Run manually with: python ytsh.py"
}
