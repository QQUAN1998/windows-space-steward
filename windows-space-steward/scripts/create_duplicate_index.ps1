param(
  [Parameter(Mandatory = $true)]
  [string]$DecisionsCsv,
  [string]$IndexRoot
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $DecisionsCsv)) {
  throw "DecisionsCsv not found: $DecisionsCsv"
}

if (-not $IndexRoot) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $IndexRoot = Join-Path ([Environment]::GetFolderPath("Desktop")) "duplicate-retained-index-$stamp"
}

New-Item -ItemType Directory -Force -Path $IndexRoot | Out-Null
$shell = New-Object -ComObject WScript.Shell
$decisions = Import-Csv -LiteralPath $DecisionsCsv
$log = New-Object System.Collections.Generic.List[object]

foreach ($decision in $decisions) {
  $groupId = $decision.GroupId
  $keptPath = $decision.KeptPath
  $removedPath = $decision.RemovedPath
  if (-not $groupId -or -not $keptPath) {
    throw "Each decision row must include GroupId and KeptPath."
  }
  if (-not (Test-Path -LiteralPath $keptPath)) {
    throw "KeptPath does not exist: $keptPath"
  }

  $safeName = ("group-{0:D2}-{1}" -f [int]$groupId, [IO.Path]::GetFileName($keptPath))
  foreach ($invalid in [IO.Path]::GetInvalidFileNameChars()) {
    $safeName = $safeName.Replace($invalid, '_')
  }
  $groupDir = Join-Path $IndexRoot $safeName
  New-Item -ItemType Directory -Force -Path $groupDir | Out-Null

  $shortcutPath = Join-Path $groupDir "retained-file.lnk"
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $keptPath
  $shortcut.WorkingDirectory = Split-Path -Parent $keptPath
  $shortcut.Description = "Retained duplicate file"
  $shortcut.Save()

  $note = @(
    "GroupId: $groupId",
    "KeptPath: $keptPath",
    "RemovedPath: $removedPath",
    "Impact: $($decision.Impact)",
    "ProcessedAt: $(Get-Date -Format o)"
  ) -join [Environment]::NewLine
  Set-Content -LiteralPath (Join-Path $groupDir "paths.txt") -Value $note -Encoding UTF8

  $log.Add([PSCustomObject]@{
    GroupId = $groupId
    KeptPath = $keptPath
    RemovedPath = $removedPath
    ShortcutPath = $shortcutPath
    Impact = $decision.Impact
  })
}

$logPath = Join-Path $IndexRoot "duplicate-decisions-log.csv"
$log | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8
Write-Output "Created duplicate retained-file index: $IndexRoot"
