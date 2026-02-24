@echo off
powershell.exe -ExecutionPolicy Bypass -Command ^
  "$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json';" ^
  "$marketplaceName = 'internal-plugins';" ^
  "$pluginName = 'mnemo@internal-plugins';" ^
  "" ^
  "if (-not (Test-Path $settingsPath)) {" ^
  "  Write-Host 'Nothing to uninstall.' -ForegroundColor Yellow; exit 0" ^
  "}" ^
  "" ^
  "$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json;" ^
  "$changed = $false;" ^
  "" ^
  "# Remove enabled plugin" ^
  "if ($settings.PSObject.Properties['enabledPlugins'] -and $settings.enabledPlugins.PSObject.Properties[$pluginName]) {" ^
  "  $settings.enabledPlugins.PSObject.Properties.Remove($pluginName);" ^
  "  $changed = $true" ^
  "}" ^
  "" ^
  "# Remove marketplace" ^
  "if ($settings.PSObject.Properties['extraKnownMarketplaces'] -and $settings.extraKnownMarketplaces.PSObject.Properties[$marketplaceName]) {" ^
  "  $settings.extraKnownMarketplaces.PSObject.Properties.Remove($marketplaceName);" ^
  "  $changed = $true" ^
  "}" ^
  "" ^
  "# Clean up empty objects" ^
  "if ($settings.PSObject.Properties['enabledPlugins'] -and $settings.enabledPlugins.PSObject.Properties.Count -eq 0) {" ^
  "  $settings.PSObject.Properties.Remove('enabledPlugins')" ^
  "}" ^
  "if ($settings.PSObject.Properties['extraKnownMarketplaces'] -and $settings.extraKnownMarketplaces.PSObject.Properties.Count -eq 0) {" ^
  "  $settings.PSObject.Properties.Remove('extraKnownMarketplaces')" ^
  "}" ^
  "" ^
  "if (-not $changed) {" ^
  "  Write-Host 'Nothing to uninstall.' -ForegroundColor Yellow; exit 0" ^
  "}" ^
  "" ^
  "# Write settings back" ^
  "$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8;" ^
  "" ^
  "Write-Host 'Mnemo memory plugin uninstalled!' -ForegroundColor Green;" ^
  "Write-Host '';" ^
  "Write-Host 'Restart Claude Code to take effect.'"
echo.
pause
