param(
  [string[]]$Paths,
  [string]$PreferredDataRoot = "D:\",
  [int]$WarnFreeGB = 80,
  [int]$HardFloorGB = 40
)

$ErrorActionPreference = "Stop"

function Normalize-PathText {
  param([string]$PathText)

  try {
    return [System.IO.Path]::GetFullPath($PathText)
  }
  catch {
    return $PathText
  }
}

function Starts-WithPath {
  param(
    [string]$Value,
    [string]$Prefix
  )

  return $Value.StartsWith($Prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

if (!$Paths -or $Paths.Count -eq 0) {
  $userProfile = [Environment]::GetFolderPath("UserProfile")
  $Paths = @(
    (Get-Location).Path,
    (Join-Path $userProfile "Downloads"),
    (Join-Path $userProfile ".cache"),
    (Join-Path $userProfile "Desktop"),
    (Join-Path $userProfile "Documents")
  )
}

$userProfile = [Environment]::GetFolderPath("UserProfile")
$preferredRoot = Normalize-PathText $PreferredDataRoot
$allowedRoots = @(
  "C:\Windows",
  "C:\Program Files",
  "C:\Program Files (x86)",
  "C:\ProgramData"
)
$warnRoots = @(
  (Join-Path $userProfile "Downloads"),
  (Join-Path $userProfile "Desktop"),
  (Join-Path $userProfile "Documents")
)
$forbiddenPatterns = @(
  "\\node_modules(\\|$)",
  "\\.venv(\\|$)",
  "\\venv(\\|$)",
  "\\.cache(\\|$)",
  "\\huggingface(\\|$)",
  "\\models(\\|$)",
  "\\datasets(\\|$)",
  "\\checkpoints(\\|$)",
  "\\weights(\\|$)",
  "\\dist(\\|$)",
  "\\build(\\|$)",
  "\\target(\\|$)",
  "\\.nuget(\\|$)",
  "\\.cargo(\\|$)",
  "\\.rustup(\\|$)",
  "\\.ollama(\\|$)"
)

$cDrive = Get-PSDrive -Name C -ErrorAction Stop
$freeGb = [math]::Round($cDrive.Free / 1GB, 2)
$pressure = if ($freeGb -lt $HardFloorGB) {
  "hard-floor"
}
elseif ($freeGb -lt $WarnFreeGB) {
  "warning"
}
else {
  "healthy"
}

Write-Output "## C Drive Pressure"
[pscustomobject]@{
  FreeGB = $freeGb
  WarnBelowGB = $WarnFreeGB
  HardFloorGB = $HardFloorGB
  Status = $pressure
} | Format-Table -AutoSize

$results = foreach ($rawPath in $Paths) {
  $path = Normalize-PathText $rawPath
  $classification = "review-c-path"
  $reason = "Review this path before placing more data on C:."
  $recommendation = "Inspect size and move growth paths off C: if needed."

  if (Starts-WithPath -Value $path -Prefix $preferredRoot) {
    $classification = "preferred-non-system"
    $reason = "This path is already under the preferred non-system root."
    $recommendation = "Keep heavy AI work here."
  }
  elseif ($path -match '^[A-Za-z]:\\' -and !$path.StartsWith("C:\", [System.StringComparison]::OrdinalIgnoreCase)) {
    $classification = "non-system-drive"
    $reason = "This path is not on C:."
    $recommendation = "Preferred for repos, caches, models, and temp output."
  }
  elseif ($allowedRoots | Where-Object { Starts-WithPath -Value $path -Prefix $_ }) {
    $classification = "allowed-core-system"
    $reason = "This path is within a core system root."
    $recommendation = "Do not relocate or clean blindly."
  }
  elseif ($warnRoots | Where-Object { Starts-WithPath -Value $path -Prefix $_ }) {
    $classification = "warn-review"
    $reason = "This user-data path can grow large on C:."
    $recommendation = "Review size and move bulky content off C:."
  }
  elseif ($forbiddenPatterns | Where-Object { $path -match $_ }) {
    $classification = "forbidden-heavy-on-c"
    $reason = "This looks like a heavy cache, model, build, or workspace growth path on C:."
    $recommendation = "Move or relocate it off C:."
  }
  elseif (Starts-WithPath -Value $path -Prefix $userProfile) {
    $classification = "warn-user-profile-on-c"
    $reason = "This is inside the user profile on C:."
    $recommendation = "Keep only light settings here; move heavy work elsewhere."
  }

  [pscustomobject]@{
    Path = $path
    Classification = $classification
    Reason = $reason
    Recommendation = $recommendation
  }
}

Write-Output ""
Write-Output "## Boundary Classification"
$results | Format-Table -Wrap -AutoSize
