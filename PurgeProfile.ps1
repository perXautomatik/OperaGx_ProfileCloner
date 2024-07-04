    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [alias("driveLetter")][string]$driveLet,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$pathSufix,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$childNode,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$CopyToCache,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$preserve,
        [Parameter(Mandatory=$false)]
        [string[]]$ExcludedExtensions,
        [string[]]$ExcludedFileNames,
        [string]$SessionStorage
    )
    $profilePath = Join-Path -Path $driveLet -ChildPath $pathSufix
    $originalProfilePath = Join-Path -Path $profilePath -ChildPath $childNode
    
    $prepParam = @{
        # Define the profile path
        datePrefix = (Get-Date -Format "yyyyMMddHHmmss")
        profilePath = $profilePath
        renamedProfilePath = Join-Path -Path $profilePath -ChildPath "$(Get-Date -Format "yyyyMMddHHmmss")-$childNode"
        originalProfilePath = $originalProfilePath
        cachePath = Join-Path -Path $originalProfilePath -ChildPath "Cache\Cache_data"
    }

    # Rename the profile folder
try {
    Rename-Item -Path $prepParam.originalProfilePath -NewName $prepParam.renamedProfilePath
}
catch {
    Write-Host "failed to Rename the profile folder"
    break
}

    # Ensure the cache directory exists
    if (-not (Test-Path -Path $prepParam.cachePath)) {
        New-Item -ItemType Directory -Path $prepParam.cachePath
    }

    # Copy items to cache
    foreach ($ctcItem in $CopyToCache) {
        $ctcSource = Join-Path -Path $prepParam.renamedProfilePath -ChildPath $ctcItem

        $files = $ctcSource | % {Get-ChildItem -Path $_ -Recurse -File }
        $files | % {
                $ctcDestiny = Join-Path -Path $prepParam.cachePath -ChildPath (Split-Path $_.name -Leaf)
                if (Test-Path -Path $_.FullName) {
                    Copy-Item -Path $_.FullName -Destination $ctcDestiny -Recurse -Force -PassThru
                }
            }
    }

   # Discover which folders to preserve
   $actualPreserveFolders = @()
   foreach ($p in $preserve) {
       $fullPath = Join-Path -Path $prepParam.renamedProfilePath -ChildPath $p
       if (Test-Path -Path $fullPath) {
           $actualPreserveFolders += $p
       }
   }
   
   Write-Host "----------------Copy items to cache and preserve items"
   
   foreach ($c in ($CopyToCache + $actualPreserveFolders)) {
       $sourcePath = Join-Path -Path $prepParam.renamedProfilePath -ChildPath $c
       $destinationPath = $originalProfilePath
       if (Test-Path -Path $sourcePath) {
           Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force -PassThru
       }
       else {
            Write-Host "failed to copy $c"
       }
   }

   # Verify preserved items
   $verificationPassed = $true
   foreach ($a in $actualPreserveFolders) {
       $preservedPath = Join-Path -Path $originalProfilePath -ChildPath $a
       if (-not (Test-Path -Path $preservedPath)) {
           $verificationPassed = $false
           Write-Host "Verification failed for $a"
           break
       }
   }

    # Delete the renamed folder if verification passed
    if ($verificationPassed) {
        Remove-Item -Path $prepParam.renamedProfilePath -Recurse -Force
    } else {
        Write-Host "Preservation verification failed. The renamed profile folder will not be deleted."
    }

