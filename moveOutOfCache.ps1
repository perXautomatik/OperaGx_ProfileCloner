# Function to move files out from cache and track them with checksums
function MoveOutFromCache {
    [CmdletBinding()]
    param (
	[string]$ProfileName = "a_vin",
	[string]$DriveLetter = "E:",
	[string]$SessionStorage,
	[string]$ProfileLocation,
	[string]$CacheFolderName = "cache",
	[string]$InnerCacheFolder = "cache_data",
	[string[]]$ExcludedExtensions = @(".pam", ".zip", ".tar", ".gz", ".null", ".gpg", ".woff2", ".woff", ".bs", ".ini")
    )

    $dateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $newFolderPath = Join-Path -Path $SessionStorage -ChildPath $dateTime
    New-Item -ItemType Directory -Force -Path $newFolderPath

    $cachePath = Join-Path -Path $ProfileLocation -ChildPath $CacheFolderName
    $innerCachePath = Join-Path -Path $cachePath -ChildPath $InnerCacheFolder
    $filesInCache = Get-ChildItem -Path $innerCachePath -File

    # Track files that are not moved
    $checksumFile = Join-Path -Path $SessionStorage -ChildPath ".cache_checksums_$dateTime.txt"
    $filesNotMoved = @()

    foreach ($file in $filesInCache) {
	if ($file.Extension -notin $ExcludedExtensions) {
	    Move-Item -Path $file.FullName -Destination $newFolderPath
	} else {
	    $checksum = Get-FileHash -Path $file.FullName -Algorithm MD5
	    $filesNotMoved += "$($file.Name):$($checksum.Hash)"
	}
    }

    # Save the checksums of files not moved to a hidden file
    $filesNotMoved | Out-File -FilePath $checksumFile -Force
    $fileInfo = Get-Item -Path $checksumFile
    $fileInfo.Attributes = 'Hidden'
}
function Move-BasedOnExtension {
    [CmdletBinding()]
    param (
	[Parameter(Mandatory)]
	[string]$OriginalFolderPath,
	[Parameter(Mandatory)]
	[string]$ExcludedExtension,
	[Parameter(Mandatory)]
	[string]$NewFolderPath
    )
    $exect = @($ExcludedExtension -split ",")
    $unfiltered = Get-ChildItem -Path $OriginalFolderPath -File
    $withExtensions = $unfiltered | Where-Object { $_.Extension }
    $filteredToMove = $withExtensions | Where-Object { $_.Extension -notin $exect }
    $zz = $filteredToMove.Length
    $z = [bool]$zz -gt 0

    if ($z) {
	New-Item -ItemType Directory -Force -Path $NewFolderPath
	$filteredToMove | ForEach-Object { Move-Item -Path $_.FullName -Destination $NewFolderPath -PassThru }
	Write-Host ("Moved " + $filteredToMove.Length + " items to " + $NewFolderPath)
    } else {
	Write-Host "No files to move."
    }
}

# Function to get session ID based on file creation times
function Get-SessionId {
    [CmdletBinding()]
    param (
	[Parameter(Mandatory)]
	[string]$ChildPath
    )

    $internalItems = Get-ChildItem -Path $ChildPath
    $firstFile = ($internalItems | Sort-Object CreationTime | Select-Object -First 1).CreationTime
    $lastFile = ($internalItems | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime
    $q = $lastFile - $firstFile

    if ($q.Days -gt 0) {
	$from = Get-Date -Date $firstFile -Format "yyMMdd_HHmmss"
	$to = Get-Date -Date $lastFile -Format "yyMMdd_HHmmss"
    }

    $sessionId = Get-Date -Format "yyMMdd_HHmmss"
    return $sessionId
}

# Function to clear cache with checksum comparison
function Clear-Cache {
    [CmdletBinding()]
    param (
	[Alias("DriveLet")]
	[string]$DriveLetter,
	[string]$PathSuffix,
	[Alias("ProfileName")]
	[string]$ChildNode,
	[string]$ExcludedExtensions
    )

    $sourceFold = Join-Path -Path $DriveLetter -ChildPath $PathSuffix
    $profileLocation = Join-Path -Path $sourceFold -ChildPath $ChildNode
    $sessionStorage = "$DriveLetter\sessionStorage"

    Push-Location
    Set-Location $sourceFold

    # Check for the hidden checksum file
    $checksumFilePattern = ".cache_checksums_*.txt"
    $checksumFiles = Get-ChildItem -Path $sessionStorage -Filter $checksumFilePattern -Hidden -File

    foreach ($checksumFile in $checksumFiles) {
	$previousChecksums = Get-Content -Path $checksumFile.FullName
	$currentFiles = Get-ChildItem -Path $profileLocation -File

	foreach ($file in $currentFiles) {
	    $currentChecksum = Get-FileHash -Path $file.FullName -Algorithm MD5
	    $previousEntry = $previousChecksums | Where-Object { $_ -match "^$($file.Name):" }

	    if ($previousEntry -and ($previousEntry.Split(':')[1] -ne $currentChecksum.Hash)) {
		# File has changed, run SetFileExtensionThroughPiping
		$file.FullName | Set-FileExtensionThroughPiping
	    }
	}

	# After processing, remove the checksum file
	Remove-Item -Path $checksumFile.FullName -Force
    }

    # Now proceed with moving files based on extension
    $filesAfterPiping = Get-ChildItem -Path $profileLocation -File
    $filesRenamed = Compare-Object -ReferenceObject $currentFiles -DifferenceObject $filesAfterPiping -Property Name | Where-Object { $_.SideIndicator -eq "=>" }

    if ($filesRenamed) {
	$newFolderPath = Join-Path -Path $sessionStorage -ChildPath (Get-Date -Format "yyyyMMdd_HHmmss")
	Move-BasedOnExtension -OriginalFolderPath $profileLocation -ExcludedExtension $ExcludedExtensions -NewFolderPath $newFolderPath
    }

    Pop-Location
}
