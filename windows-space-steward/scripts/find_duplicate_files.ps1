param(
  [string[]]$Roots,
  [int]$MinSizeMB = 5,
  [string]$OutputCsv
)

$ErrorActionPreference = "Stop"

function Get-DefaultRoots {
  $roots = @()
  $user = $env:USERPROFILE
  foreach ($path in @(
    (Join-Path $user "Desktop"),
    (Join-Path $user "Documents"),
    (Join-Path $user "Downloads"),
    "C:\tmp",
    "D:\DesktopArchive",
    "D:\MigratedFromC"
  )) {
    if (Test-Path -LiteralPath $path) { $roots += $path }
  }
  if (Test-Path -LiteralPath "D:\") {
    foreach ($child in Get-ChildItem -LiteralPath "D:\" -Directory -Force -ErrorAction SilentlyContinue) {
      if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($child.Name -in @('$RECYCLE.BIN', 'System Volume Information')) { continue }
      $roots += $child.FullName
    }
  }
  return $roots | Select-Object -Unique
}

function Test-SkippedPath([string]$Path) {
  $normalized = $Path.TrimEnd('\')
  $skipPrefixes = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData",
    (Join-Path $env:USERPROFILE "AppData")
  )
  foreach ($prefix in $skipPrefixes) {
    if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  return $false
}

function Get-FilesNoReparse([string[]]$StartRoots, [int64]$MinBytes) {
  $results = New-Object System.Collections.Generic.List[object]
  $stack = New-Object System.Collections.Generic.Stack[string]

  foreach ($root in $StartRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    if (Test-SkippedPath $root) { continue }
    $item = Get-Item -LiteralPath $root -Force -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
    $stack.Push($item.FullName)
  }

  while ($stack.Count -gt 0) {
    $dir = $stack.Pop()
    foreach ($entry in Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue) {
      if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($entry.PSIsContainer) {
        if (-not (Test-SkippedPath $entry.FullName)) { $stack.Push($entry.FullName) }
        continue
      }
      if ($entry.Length -ge $MinBytes) { $results.Add($entry) }
    }
  }

  return $results
}

if (-not $Roots -or $Roots.Count -eq 0) {
  $Roots = Get-DefaultRoots
} else {
  $expandedRoots = @()
  foreach ($rootEntry in $Roots) {
    foreach ($part in ($rootEntry -split '[,;]')) {
      $trimmed = $part.Trim()
      if ($trimmed) { $expandedRoots += $trimmed }
    }
  }
  $Roots = $expandedRoots | Select-Object -Unique
}

$minBytes = [int64]$MinSizeMB * 1MB
Write-Output "Duplicate scan roots:"
$Roots | ForEach-Object { Write-Output " - $_" }
Write-Output "Minimum file size: $MinSizeMB MB"

$files = Get-FilesNoReparse -StartRoots $Roots -MinBytes $minBytes
$sizeGroups = $files | Group-Object Length | Where-Object { $_.Count -gt 1 }

$rows = New-Object System.Collections.Generic.List[object]
$groupId = 0
foreach ($sizeGroup in $sizeGroups) {
  $hashRows = foreach ($file in $sizeGroup.Group) {
    try {
      $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop
      [PSCustomObject]@{
        Hash = $hash.Hash
        Path = $file.FullName
        SizeBytes = $file.Length
        LastWriteTime = $file.LastWriteTime
        Drive = ([System.IO.Path]::GetPathRoot($file.FullName)).TrimEnd('\')
      }
    } catch {
      [PSCustomObject]@{
        Hash = "ERROR: $($_.Exception.Message)"
        Path = $file.FullName
        SizeBytes = $file.Length
        LastWriteTime = $file.LastWriteTime
        Drive = ([System.IO.Path]::GetPathRoot($file.FullName)).TrimEnd('\')
      }
    }
  }

  foreach ($hashGroup in ($hashRows | Where-Object { $_.Hash -notlike "ERROR:*" } | Group-Object Hash | Where-Object { $_.Count -gt 1 })) {
    $groupId += 1
    $drives = @($hashGroup.Group | Select-Object -ExpandProperty Drive -Unique)
    $recommendedKeep = if ($drives -contains "D:" -and $drives -contains "C:") { "Prefer D: copy" } else { "Ask user" }
    foreach ($match in $hashGroup.Group) {
      $rows.Add([PSCustomObject]@{
        GroupId = $groupId
        SizeMB = [math]::Round($match.SizeBytes / 1MB, 2)
        Hash = $match.Hash
        Drive = $match.Drive
        Path = $match.Path
        LastWriteTime = $match.LastWriteTime
        RecommendedKeep = $recommendedKeep
        Impact = "If this copy is removed, content remains available only at the kept path. Create a desktop shortcut index after action."
      })
    }
  }
}

if ($OutputCsv) {
  $parent = Split-Path -Parent $OutputCsv
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $rows | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding UTF8
  Write-Output "Wrote duplicate candidates to $OutputCsv"
}

if ($rows.Count -eq 0) {
  Write-Output "No true duplicate files found above threshold."
} else {
  $rows | Sort-Object GroupId, Drive, Path | Format-Table GroupId, SizeMB, Drive, Path, RecommendedKeep -AutoSize
}
