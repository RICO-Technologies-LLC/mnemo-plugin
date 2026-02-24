@echo off
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\") do set "MARKETPLACE_DIR=%%~fI"
powershell.exe -ExecutionPolicy Bypass -Command ^
  "$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json';" ^
  "$marketplaceName = 'internal-plugins';" ^
  "$pluginName = 'mnemo@internal-plugins';" ^
  "$marketplacePath = '%MARKETPLACE_DIR:\=/%';" ^
  "" ^
  "# Ensure .claude directory exists" ^
  "$claudeDir = Join-Path $env:USERPROFILE '.claude';" ^
  "if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }" ^
  "" ^
  "# Load or create settings" ^
  "if (Test-Path $settingsPath) {" ^
  "  $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json" ^
  "} else {" ^
  "  $settings = [PSCustomObject]@{}" ^
  "}" ^
  "" ^
  "# Add extraKnownMarketplaces if missing" ^
  "if (-not $settings.PSObject.Properties['extraKnownMarketplaces']) {" ^
  "  $settings | Add-Member -NotePropertyName 'extraKnownMarketplaces' -NotePropertyValue ([PSCustomObject]@{})" ^
  "}" ^
  "if (-not $settings.extraKnownMarketplaces.PSObject.Properties[$marketplaceName]) {" ^
  "  $settings.extraKnownMarketplaces | Add-Member -NotePropertyName $marketplaceName -NotePropertyValue ([PSCustomObject]@{" ^
  "    source = [PSCustomObject]@{ source = 'directory'; path = $marketplacePath }" ^
  "  })" ^
  "}" ^
  "" ^
  "# Add enabledPlugins if missing" ^
  "if (-not $settings.PSObject.Properties['enabledPlugins']) {" ^
  "  $settings | Add-Member -NotePropertyName 'enabledPlugins' -NotePropertyValue ([PSCustomObject]@{})" ^
  "}" ^
  "if (-not $settings.enabledPlugins.PSObject.Properties[$pluginName]) {" ^
  "  $settings.enabledPlugins | Add-Member -NotePropertyName $pluginName -NotePropertyValue $true" ^
  "}" ^
  "" ^
  "# Write settings back" ^
  "$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8;" ^
  "" ^
  "Write-Host 'Mnemo memory plugin installed!' -ForegroundColor Green;" ^
  "Write-Host '';" ^
  "Write-Host 'Restart Claude Code to activate.'"
echo.
pause
