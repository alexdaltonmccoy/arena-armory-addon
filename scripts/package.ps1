# Packages the ArenaArmory addon into a CurseForge-ready zip for local/manual
# use. Official releases are built by .github/workflows/release.yml (BigWigs
# packager) on tag push, which also stamps @project-version@ from the tag.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\package.ps1 [-Version 1.2.0]
param([string]$Version = "dev")
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$version = $Version

$dist = Join-Path $repo "dist"
$stage = Join-Path $dist "stage\ArenaArmory"
if (Test-Path (Join-Path $dist "stage")) { Remove-Item (Join-Path $dist "stage") -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

# The zip must contain a single top-level "ArenaArmory" folder.
Copy-Item (Join-Path $repo "ArenaArmory\*") $stage -Recurse

# Stamp the packager's version token so manual zips don't ship the raw token.
$tocPath = Join-Path $stage "ArenaArmory.toc"
(Get-Content $tocPath) -replace '@project-version@', $version | Set-Content $tocPath

$zip = Join-Path $dist "ArenaArmory-v$version.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip

Remove-Item (Join-Path $dist "stage") -Recurse -Force
Write-Host "Packaged: $zip"
