[CmdletBinding()]
param (
  [Parameter(Mandatory = $true)]
  [string] $ConfigFilePath = "CacheSort.ini"
)

# Function to read settings from the INI file
function Get-CacheSortConfig {
  param (
    [string] $FilePath = $ConfigFilePath
  )

  if (!(Test-Path $FilePath)) {
    Write-Warning "The configuration file '$FilePath' not found. Using default settings."
    return @{
      SourceFolder = ""
      TargetFolderPattern = "{0}\cache\{1}"
      ExcludedExtensions = "dat,db"
      SessionIdPattern = "yyMMdd_HHmmss"
      UseSessionId = $true
      MoveFiles = $true
    }
  }

  $config = Get-Content -Path $FilePath | ConvertFrom-Json

  # Validate and potentially set default values for missing settings
  $config | Add-Member -MemberType NoteProperty -Name SourceFolder -Value (if ($config.SourceFolder) { $config.SourceFolder } else { "" })
  $config | Add-Member -MemberType NoteProperty -Name TargetFolderPattern -Value (if ($config.TargetFolderPattern) { $config.TargetFolderPattern } else { "{0}\cache\{1}" })
  $config | Add-Member -MemberType NoteProperty -Name ExcludedExtensions -Value (if ($config.ExcludedExtensions) { $config.ExcludedExtensions } else { "dat,db" })
  $config | Add-Member -MemberType NoteProperty -Name SessionIdPattern -Value (if ($config.SessionIdPattern) { $config.SessionIdPattern } else { "yyMMdd_HHmmss" })
  $config | Add-Member -MemberType NoteProperty -Name UseSessionId -Value (if (({$config.UseSessionId}).is[bool]) { $config.UseSessionId } else { $true })
  $config | Add-Member -MemberType NoteProperty -Name MoveFiles -Value (if (({$config.MoveFiles}).is[bool]) { $config.MoveFiles } else { $true })

  return $config
}

# Function to get the session ID (if enabled in config)
function Get-SessionId {
  param (
    [string] $ChildPath,
    [hashtable] $Config
  )

  if ($Config.UseSessionId) {
    $internalItems = Get-ChildItem -Path $ChildPath
    $firtFile = ($internalItems | Sort-Object CreationTime | Select-Object -First 1).CreationTime
    $lastFile = ($internalItems | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime
    $sessionId = (Get-Date -Format $Config.SessionIdPattern)
  } else {
    $sessionId = ""
  }

  return $sessionId
}

# Function to move files based on extension
function Move-BasedOnExtension {
  param (
    [string] $SourceFolderPath,
    [string] $ExcludedExtensions,
    [string] $TargetFolderPath
  )

  $files = Get-ChildItem -Path $SourceFolderPath -File

  $filesToMove = $files | Where-Object { $_.Extension -notin $ExcludedExtensions.Split(",") }

  if ($filesToMove) {
    New-Item -ItemType Directory -Force -Path $TargetFolderPath | Out-Null

    if (Test-Path $TargetFolderPath) {
          Move-Item -Path $filesToMove.FullName -Destination $targetSubfolder -PassThru
        Write-Verbose "$($files.Count) file(s) moved to $TargetFolderPath"
    } else {
      Write-Error "Failed to create target folder: $TargetFolderPath"
      exit
    }
  } else {
      Write-Verbose "No files to move based on the specified criteria."
  }
}

# Read configuration from INI file
$config = Get-CacheSortConfig

# Process cache directories
$sourceFolders = Get-ChildItem -Path $config.SourceFolder -Directory

foreach ($folder in $sourceFolders) {
  $parentName = $folder.Name
  $targetFolder = Join-Path -Path ($config.TargetFolderPattern -f $folder.FullName, (Get-SessionId -ChildPath $folder.FullName -Config $config))

  if ((Get-ChildItem $folder -ErrorAction SilentlyContinue).Length -gt
