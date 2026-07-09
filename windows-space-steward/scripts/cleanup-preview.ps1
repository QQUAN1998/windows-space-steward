param()

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

$userProfile = [Environment]::GetFolderPath("UserProfile")
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")
$tempPath = [IO.Path]::GetTempPath()

$candidates = @(
  @{
    Category = "safe-cache-cleanup"
    Label = "User temp"
    Path = $tempPath
    SuggestedAction = "Review and clear stale files from the active temp directory."
  },
  @{
    Category = "safe-cache-cleanup"
    Label = "Windows temp"
    Path = "C:\Windows\Temp"
    SuggestedAction = "Review and clear stale temporary files if not in use."
  },
  @{
    Category = "safe-cache-cleanup"
    Label = "pip cache"
    Path = Join-Path $localAppData "pip\Cache"
    SuggestedAction = "Delete cached wheels and downloads if you do not need offline reuse."
  },
  @{
    Category = "safe-cache-cleanup"
    Label = "npm cache"
    Path = Join-Path $localAppData "npm-cache"
    SuggestedAction = "Clear npm cache or move it to D:\\Caches."
  },
  @{
    Category = "safe-cache-cleanup"
    Label = "uv cache"
    Path = Join-Path $localAppData "uv\cache"
    SuggestedAction = "Clear or relocate uv cache."
  },
  @{
    Category = "review-before-delete"
    Label = "NuGet packages"
    Path = Join-Path $userProfile ".nuget\packages"
    SuggestedAction = "Review package reuse before removing or relocating."
  },
  @{
    Category = "review-before-delete"
    Label = "Cargo"
    Path = Join-Path $userProfile ".cargo"
    SuggestedAction = "Review Cargo registry and git cache before cleanup."
  },
  @{
    Category = "review-before-delete"
    Label = "Rustup"
    Path = Join-Path $userProfile ".rustup"
    SuggestedAction = "Review installed toolchains before moving or pruning."
  },
  @{
    Category = "migrate-not-delete"
    Label = "Downloads"
    Path = Join-Path $userProfile "Downloads"
    SuggestedAction = "Move large installers, archives, and exports off C:."
  },
  @{
    Category = "migrate-not-delete"
    Label = "user .cache"
    Path = Join-Path $userProfile ".cache"
    SuggestedAction = "Review AI and package caches; move recurring growth paths off C:."
  },
  @{
    Category = "migrate-not-delete"
    Label = "Ollama"
    Path = Join-Path $userProfile ".ollama"
    SuggestedAction = "Move model storage off C: if it contains large weights."
  }
)

$results = @()
foreach ($candidate in $candidates) {
  $size = Get-DirectorySizeBytes $candidate.Path
  if ($null -ne $size) {
    $results += [pscustomobject]@{
      Category = $candidate.Category
      Label = $candidate.Label
      Path = $candidate.Path
      SizeBytes = [math]::Round($size)
      Size = Format-Bytes $size
      SuggestedAction = $candidate.SuggestedAction
    }
  }
}

Write-Output "## Cleanup Preview"
$results |
  Sort-Object SizeBytes -Descending |
  Select-Object Category, Label, Path, Size, SuggestedAction |
  Format-Table -Wrap -AutoSize

Write-Output ""
Write-Output "Preview only. Nothing was deleted."
Write-Output "Prefer clearing safe-cache-cleanup items first, then migrate-not-delete items off C:."
