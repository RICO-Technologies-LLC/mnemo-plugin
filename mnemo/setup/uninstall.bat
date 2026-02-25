@echo off
powershell.exe -ExecutionPolicy Bypass -Command ^
  "$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json';" ^
  "$configPath = Join-Path $env:USERPROFILE '.claude\mnemo-config.json';" ^
  "$pluginNames = @('mnemo@mnemo-plugin', 'mnemo@internal-plugins');" ^
  "$marketplaceNames = @('mnemo-plugin', 'internal-plugins');" ^
  "$mnemoPerms = @(" ^
  "  'Bash(*save-memory.sh*)'," ^
  "  'Bash(*reinforce-memory.sh*)'," ^
  "  'Bash(*deactivate-memory.sh*)'," ^
  "  'Bash(*link-memories.sh*)'," ^
  "  'Bash(*search-memories.sh*)'," ^
  "  'Bash(*mnemo-client.sh*)'" ^
  ");" ^
  "" ^
  "Write-Host ''; Write-Host '=== Mnemo Uninstall ===' -ForegroundColor Cyan; Write-Host '';" ^
  "" ^
  "# Remove config file" ^
  "if (Test-Path $configPath) {" ^
  "  Remove-Item $configPath -Force;" ^
  "  Write-Host '  Removed mnemo-config.json'" ^
  "} else {" ^
  "  Write-Host '  No config file found (already removed).'" ^
  "}" ^
  "" ^
  "# Clean settings.json" ^
  "if (-not (Test-Path $settingsPath)) {" ^
  "  Write-Host '  No settings.json found.'" ^
  "} else {" ^
  "  $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json;" ^
  "  $changed = $false;" ^
  "" ^
  "  # Remove plugin entries" ^
  "  foreach ($name in $pluginNames) {" ^
  "    if ($settings.PSObject.Properties['enabledPlugins'] -and $settings.enabledPlugins.PSObject.Properties[$name]) {" ^
  "      $settings.enabledPlugins.PSObject.Properties.Remove($name);" ^
  "      $changed = $true" ^
  "    }" ^
  "  }" ^
  "  if ($settings.PSObject.Properties['enabledPlugins'] -and $settings.enabledPlugins.PSObject.Properties.Count -eq 0) {" ^
  "    $settings.PSObject.Properties.Remove('enabledPlugins')" ^
  "  }" ^
  "" ^
  "  # Remove marketplace entries" ^
  "  foreach ($name in $marketplaceNames) {" ^
  "    if ($settings.PSObject.Properties['extraKnownMarketplaces'] -and $settings.extraKnownMarketplaces.PSObject.Properties[$name]) {" ^
  "      $settings.extraKnownMarketplaces.PSObject.Properties.Remove($name);" ^
  "      $changed = $true" ^
  "    }" ^
  "  }" ^
  "  if ($settings.PSObject.Properties['extraKnownMarketplaces'] -and $settings.extraKnownMarketplaces.PSObject.Properties.Count -eq 0) {" ^
  "    $settings.PSObject.Properties.Remove('extraKnownMarketplaces')" ^
  "  }" ^
  "" ^
  "  # Remove Mnemo permissions" ^
  "  if ($settings.PSObject.Properties['permissions'] -and $settings.permissions.PSObject.Properties['allow']) {" ^
  "    $settings.permissions.allow = @($settings.permissions.allow | Where-Object { $_ -notin $mnemoPerms });" ^
  "    $changed = $true;" ^
  "    if ($settings.permissions.allow.Count -eq 0) {" ^
  "      $settings.permissions.PSObject.Properties.Remove('allow')" ^
  "    }" ^
  "    if ($settings.permissions.PSObject.Properties.Count -eq 0) {" ^
  "      $settings.PSObject.Properties.Remove('permissions')" ^
  "    }" ^
  "  }" ^
  "" ^
  "  if ($changed) {" ^
  "    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8;" ^
  "    Write-Host '  Cleaned settings.json (plugin, marketplace, permissions)'" ^
  "  } else {" ^
  "    Write-Host '  No Mnemo entries found in settings.json.'" ^
  "  }" ^
  "}" ^
  "" ^
  "Write-Host '';" ^
  "Write-Host 'Mnemo uninstalled.' -ForegroundColor Green;" ^
  "Write-Host 'Restart Claude Code to take effect.';" ^
  "Write-Host ''"
echo.
pause
