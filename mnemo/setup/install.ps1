# install.ps1 — Install Mnemo plugin for Claude Code (Windows)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Bash detection ──
$bashOk = $false
if (Get-Command bash -ErrorAction SilentlyContinue) {
    $bashOk = $true
} else {
    $bashBinDir = $null

    # Try git --exec-path to locate Git install root
    $gitExec = $null
    try { $gitExec = & git --exec-path 2>$null } catch {}
    if ($gitExec -and (Test-Path $gitExec)) {
        $gitRoot = (Get-Item $gitExec).Parent.Parent.Parent.FullName
        $candidate = Join-Path $gitRoot 'bin\bash.exe'
        if (Test-Path $candidate) { $bashBinDir = Split-Path $candidate }
    }

    # Fallback: common install paths
    if (-not $bashBinDir) {
        foreach ($p in 'C:\Program Files\Git\bin\bash.exe', 'C:\Program Files (x86)\Git\bin\bash.exe') {
            if (Test-Path $p) { $bashBinDir = Split-Path $p; break }
        }
    }

    if ($bashBinDir) {
        $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
        if ($userPath -notlike "*$bashBinDir*") {
            [Environment]::SetEnvironmentVariable('PATH', "$userPath;$bashBinDir", 'User')
            $env:PATH = "$env:PATH;$bashBinDir"
            Write-Host "Added $bashBinDir to your PATH." -ForegroundColor Yellow
        }
        $bashOk = $true
    } else {
        Write-Host 'ERROR: bash.exe not found.' -ForegroundColor Red
        Write-Host 'Mnemo requires bash (included with Git for Windows).' -ForegroundColor Red
        Write-Host 'Install Git for Windows from https://git-scm.com/download/win'
        Write-Host 'or add the Git bin directory (e.g. C:\Program Files\Git\bin) to your PATH.'
        exit 1
    }
}
if (-not $bashOk) { exit 1 }

# ── Plugin registration ──
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$marketplaceDir = (Resolve-Path (Join-Path $scriptDir '..\..\')).Path

$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
$marketplaceName = 'internal-plugins'
$pluginName = 'mnemo@internal-plugins'
$marketplacePath = $marketplaceDir -replace '\\', '/'

# Ensure .claude directory exists
$claudeDir = Join-Path $env:USERPROFILE '.claude'
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }

# Load or create settings
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

# Add extraKnownMarketplaces if missing
if (-not $settings.PSObject.Properties['extraKnownMarketplaces']) {
    $settings | Add-Member -NotePropertyName 'extraKnownMarketplaces' -NotePropertyValue ([PSCustomObject]@{})
}
if (-not $settings.extraKnownMarketplaces.PSObject.Properties[$marketplaceName]) {
    $settings.extraKnownMarketplaces | Add-Member -NotePropertyName $marketplaceName -NotePropertyValue ([PSCustomObject]@{
        source = [PSCustomObject]@{ source = 'directory'; path = $marketplacePath }
    })
}

# Add enabledPlugins if missing
if (-not $settings.PSObject.Properties['enabledPlugins']) {
    $settings | Add-Member -NotePropertyName 'enabledPlugins' -NotePropertyValue ([PSCustomObject]@{})
}
if (-not $settings.enabledPlugins.PSObject.Properties[$pluginName]) {
    $settings.enabledPlugins | Add-Member -NotePropertyName $pluginName -NotePropertyValue $true
}

# Write settings back
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8

Write-Host 'Mnemo memory plugin installed!' -ForegroundColor Green
Write-Host ''
Write-Host 'Restart Claude Code to activate.'
