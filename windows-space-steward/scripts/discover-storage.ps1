param(
  [string]$Drive = "C",
  [int]$Top = 10
)

$ErrorActionPreference = "Stop"

function Format-Bytes {
  param([double]$Bytes)

  if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
  if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
  if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
  if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
  return "{0:N0} B" -f $Bytes
}

function Get-DirectorySizeBytes {
  param([string]$Path)

  if (!(Test-Path -LiteralPath $Path)) { return $null }

  try {
    $sum = Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
      Measure-Object -Property Length -Sum
    if ($null -eq $sum.Sum) { return [double]0 }
    return [double]$sum.Sum
  }
  catch {
    return $null
  }
}

function Write-Section {
  param([string]$Title)
  Write-Output ""
  Write-Output "## $Title"
}

$driveLetter = $Drive.TrimEnd(":")
$root = "$driveLetter`:\"
$psDrive = Get-PSDrive -Name $driveLetter -ErrorAction Stop
$userProfile = [Environment]::GetFolderPath("UserProfile")
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")

Write-Section "Drive Summary"
$used = $psDrive.Used
$free = $psDrive.Free
$total = $used + $free
[pscustomobject]@{
  Drive = $root
  Used = Format-Bytes $used
  Free = Format-Bytes $free
  Total = Format-Bytes $total
} | Format-Table -AutoSize

Write-Section "Largest Root Folders"
$rootResults = @()
Get-ChildItem -LiteralPath $root -Force -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $size = Get-DirectorySizeBytes $_.FullName
  if ($null -ne $size) {
    $rootResults += [pscustomobject]@{
      Path = $_.FullName
      SizeBytes = [math]::Round($size)
      Size = Format-Bytes $size
    }
  }
}

$rootResults |
  Sort-Object SizeBytes -Descending |
  Select-Object -First $Top Path, Size |
  Format-Table -AutoSize

Write-Section "Hotspots"
$hotspots = @(
  @{ Label = "Downloads"; Path = Join-Path $userProfile "Downloads" },
  @{ Label = "Desktop"; Path = Join-Path $userProfile "Desktop" },
  @{ Label = "Documents"; Path = Join-Path $userProfile "Documents" },
  @{ Label = "Temp"; Path = Join-Path $localAppData "Temp" },
  @{ Label = "Packages"; Path = Join-Path $localAppData "Packages" },
  @{ Label = "pip cache"; Path = Join-Path $localAppData "pip\Cache" },
  @{ Label = "npm cache"; Path = Join-Path $localAppData "npm-cache" },
  @{ Label = "uv cache"; Path = Join-Path $localAppData "uv\cache" },
  @{ Label = "user .cache"; Path = Join-Path $userProfile ".cache" },
  @{ Label = "NuGet packages"; Path = Join-Path $userProfile ".nuget\packages" },
  @{ Label = "Cargo"; Path = Join-Path $userProfile ".cargo" },
  @{ Label = "Rustup"; Path = Join-Path $userProfile ".rustup" },
  @{ Label = "Ollama"; Path = Join-Path $userProfile ".ollama" }
)

$hotspotResults = @()
foreach ($item in $hotspots) {
  $size = Get-DirectorySizeBytes $item.Path
  if ($null -ne $size) {
    $hotspotResults += [pscustomobject]@{
      Label = $item.Label
      Path = $item.Path
      SizeBytes = [math]::Round($size)
      Size = Format-Bytes $size
    }
  }
}

$hotspotResults |
  Sort-Object SizeBytes -Descending |
  Select-Object Label, Path, Size |
  Format-Table -AutoSize

Write-Section "Notes"
Write-Output "Use cleanup-preview.ps1 next for a safer reclaim-first view."
Write-Output "Use check-boundary.ps1 to classify repos, caches, models, and work roots on or off C:."
