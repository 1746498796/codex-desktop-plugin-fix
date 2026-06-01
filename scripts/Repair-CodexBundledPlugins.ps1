<#
.SYNOPSIS
  Repair local Codex Desktop bundled plugin marketplace on Windows.

.DESCRIPTION
  Copies the official Codex Desktop openai-bundled plugins from the WindowsApps
  installation directory into a persistent local marketplace under ~/.codex.
  It also creates the required .agents/plugins/marketplace.json manifest path.

  By default this script does NOT modify config.toml. Use -PatchConfig only if
  you have reviewed your config and accept an automatic append when no duplicate
  sections are detected.
#>

param(
  [string]$InstallRoot,
  [string]$CodexHome = (Join-Path $env:USERPROFILE '.codex'),
  [switch]$PatchConfig
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
  Write-Host "[codex-plugin-fix] $msg" -ForegroundColor Cyan
}

function Find-OpenAIBundledRoot {
  param([string]$ExplicitRoot)

  if ($ExplicitRoot) {
    $candidate = Join-Path $ExplicitRoot 'app\resources\plugins\openai-bundled'
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    if (Test-Path -LiteralPath (Join-Path $ExplicitRoot '.agents\plugins\marketplace.json')) { return $ExplicitRoot }
    throw "InstallRoot does not contain openai-bundled marketplace: $ExplicitRoot"
  }

  $windowsApps = 'C:\Program Files\WindowsApps'
  $roots = Get-ChildItem -LiteralPath $windowsApps -Directory -Filter 'OpenAI.Codex_*' -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName 'app\resources\plugins\openai-bundled' } |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ '.agents\plugins\marketplace.json') }

  if (-not $roots -or $roots.Count -eq 0) {
    throw "Cannot find Codex Desktop openai-bundled plugins under $windowsApps. Pass -InstallRoot manually."
  }

  return $roots[0]
}

$src = Find-OpenAIBundledRoot -ExplicitRoot $InstallRoot
$dst = Join-Path $CodexHome 'local-marketplaces\openai-bundled'
$config = Join-Path $CodexHome 'config.toml'

Write-Step "Source: $src"
Write-Step "Destination: $dst"

New-Item -ItemType Directory -Force -Path (Join-Path $dst 'plugins') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dst '.agents\plugins') | Out-Null

$srcManifest = Join-Path $src '.agents\plugins\marketplace.json'
if (-not (Test-Path -LiteralPath $srcManifest)) {
  throw "Missing source manifest: $srcManifest"
}

Copy-Item -LiteralPath $srcManifest -Destination (Join-Path $dst 'marketplace.json') -Force
Copy-Item -LiteralPath $srcManifest -Destination (Join-Path $dst '.agents\plugins\marketplace.json') -Force

$plugins = @('browser', 'chrome', 'computer-use', 'latex')
foreach ($name in $plugins) {
  $from = Join-Path $src "plugins\$name"
  $to = Join-Path $dst "plugins\$name"
  if (-not (Test-Path -LiteralPath $from)) {
    Write-Warning "Plugin not found, skip: $name ($from)"
    continue
  }

  Write-Step "Copy plugin: $name"
  robocopy $from $to /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Host
  if ($LASTEXITCODE -gt 7) {
    throw "robocopy failed for $name with code $LASTEXITCODE"
  }
}

$escapedSource = $dst.Replace('\', '\\')
$tomlBlock = @"
[marketplaces.openai-bundled]
source_type = "local"
source = '$dst'

[plugins."browser@openai-bundled"]
enabled = true

[plugins."chrome@openai-bundled"]
enabled = true

[plugins."computer-use@openai-bundled"]
enabled = true
"@

Write-Host ""
Write-Step "Required config.toml block:"
Write-Host $tomlBlock

if ($PatchConfig) {
  New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
  if (-not (Test-Path -LiteralPath $config)) {
    New-Item -ItemType File -Force -Path $config | Out-Null
  }

  $current = Get-Content -LiteralPath $config -Raw
  $duplicateHeaders = @(
    '[marketplaces.openai-bundled]',
    '[plugins."browser@openai-bundled"]',
    '[plugins."chrome@openai-bundled"]',
    '[plugins."computer-use@openai-bundled"]'
  ) | Where-Object { $current.Contains($_) }

  if ($duplicateHeaders.Count -gt 0) {
    Write-Warning "config.toml already contains related sections. Not patching automatically to avoid duplicate TOML tables:"
    $duplicateHeaders | ForEach-Object { Write-Warning "  $_" }
    Write-Warning "Please merge the config block manually."
  } else {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$config.bak-$stamp"
    Copy-Item -LiteralPath $config -Destination $backup -Force
    Add-Content -LiteralPath $config -Value "`n# Added by Repair-CodexBundledPlugins.ps1 at $stamp`n$tomlBlock"
    Write-Step "Patched config.toml. Backup: $backup"
  }
}

Write-Host ""
Write-Step "Done. Restart Codex Desktop, then run: codex plugin list"
Write-Step "Expected manifest: $(Join-Path $dst '.agents\plugins\marketplace.json')"
