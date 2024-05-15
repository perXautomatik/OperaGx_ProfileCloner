    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$driveLet,

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
        [string[]]$preserve
    )

    # Define the profile path
    $profilePath = Join-Path -Path $driveLet -ChildPath $pathSufix
    $originalProfilePath = Join-Path -Path $profilePath -ChildPath $childNode
    $datePrefix = (Get-Date -Format "yyyyMMddHHmmss")
    $renamedProfilePath = Join-Path -Path $profilePath -ChildPath "$datePrefix-$childNode"

    $cachePath = Join-Path -Path $originalProfilePath -ChildPath "Cache\Cache_data"


    # Rename the profile folder
    Rename-Item -Path $originalProfilePath -NewName $renamedProfilePath -PassThru

    # Ensure the cache directory exists
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -ItemType Directory -Path $cachePath
    }

    # Copy items to cache
    foreach ($ctcItem in $CopyToCache) {
        $ctcSource = Join-Path -Path $profilePath -ChildPath $ctcItem
        $ctcDestiny = Join-Path -Path $cachePath -ChildPath (Split-Path $ctcItem -Leaf)
        if (Test-Path -Path $ctcSource) {
            Copy-Item -Path $ctcSource -Destination $ctcDestiny -Recurse -Force
        }
    }
    # Copy items to cache and preserve items
    foreach ($item in ($preserve + $CopyToCache)) {
        $sourcePath = Join-Path -Path $renamedProfilePath -ChildPath $item
        $destinationPath = Join-Path -Path $originalProfilePath -ChildPath $item
        if (Test-Path -Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force -PassThru
        }
    }

    # Verify preserved items
    $verificationPassed = $true
    foreach ($item in $preserve) {
        $preservedPath = Join-Path -Path $originalProfilePath -ChildPath $item
        if (-not (Test-Path -Path $preservedPath)) {
            $verificationPassed = $false
            Write-Host "Verification failed for $item"
            break
        }
    }

    # Delete the renamed folder if verification passed
    if ($verificationPassed) {
        Remove-Item -Path $renamedProfilePath -Recurse -Force
    } else {
        Write-Host "Preservation verification failed. The renamed profile folder will not be deleted."
    }

