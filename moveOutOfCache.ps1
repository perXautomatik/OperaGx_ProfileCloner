import-module ".\lib\FileHelper.psm1"

function MoveOutFromCache { 
    param (
        $profileName = "a_vin", 
        $driveLetter = "E:", 
        $sessionStorage = "$driveLetter\sessionStorage\$profileName",
        $profileLocation = "$driveLetter\_side_profiles\$profileName\",
        $cachfoldername = "cache",
        $innerCacheFolder = "cache_data"
        ) 
    
        $dateTime = Get-Date -Format "yyyyMMdd_HHmmss";
        $excludedExtensions = @(".pam", ".zip", ".tar", ".gz", ".null", ".gpg", ".woff2", ".woff", ".bs", ".ini" );   
    cd $profileLocation ; 
    $a = @(); 
    $q = (get-childitem  -dept 1 -include $cachfoldername) ; 
    
    $a = @($q | get-childitem -filter $innerCacheFolder | select fullname) ; 
    
    $a | % { 
        ( set-clipboard $_.fullname | & SetFileExtension ) ; 
    
        $originalFolderPath = $_.fullname ; 
        
        $newFolderPath = Join-Path ($sessionStorage) $dateTime ; 
        
        New-Item -ItemType Directory -Force -Path $newFolderPath ;
        
        Get-ChildItem -Path $originalFolderPath -File | 
            ? { $_.Extension } | 
                ? { $_.Extension -notin $excludedExtensions } |
                % { 
                        Move-Item -Path $_.FullName -Destination $newFolderPath 
                    } } }
# Function to move files based on their extension
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

# Function to clear cache
function Clear-Cache {
    [CmdletBinding()]
    param (
	[Parameter(Mandatory)]
	[Alias("DriveLet")]
	[string]$DriveLetter,
	[Parameter(Mandatory)]
	[string]$PathSuffix,
	[Parameter(Mandatory)]
	[Alias("ProfileName")]
	[string]$ChildNode,
	[Parameter(Mandatory)]
	[string]$ExcludedExtensions
    )

    $sourceFold = Join-Path -Path $DriveLetter -ChildPath $PathSuffix
    $profileLocation = Join-Path -Path $sourceFold -ChildPath $ChildNode
    $sessionStorage = "$DriveLetter\sessionStorage"

    Push-Location
    Set-Location $sourceFold

    $unfiltered = @(Get-ChildItem -Path $profileLocation -Depth 1 -Include "cache" | Get-ChildItem)
    foreach ($item in $unfiltered) {
	$childNode = $item.Parent.Parent
	$sesStor =  Join-Path $sessionStorage $childNode
	$sessionId = Get-SessionId -ChildPath $childNode
	$newFol = Join-Path -Path $sesStor -ChildPath $sessionId

	if (!(Test-Path -Path $newFol)) {
	    $item.FullName | Set-FileExtensionThroughPiping
	    Move-BasedOnExtension -OriginalFolderPath $item.FullName -ExcludedExtension $ExcludedExtensions -NewFolderPath $newFol
	} else {
	    Write-Debug "Session already exists."
	}
    }

    Pop-Location
}
