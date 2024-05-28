# Function to test if a command exists in the current session
function Test-CommandExists {
    [CmdletBinding()]
    Param (
	[Parameter(Mandatory)]
	[string]$Command
    )
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
	Get-Command $Command | Out-Null
	return $true
    } catch {
	return $false
    } finally {
	$ErrorActionPreference = $oldErrorActionPreference
    }
}

# Function to create an empty file
function Touch {
    [CmdletBinding()]
    Param (
	[Parameter(Mandatory)]
	[string]$File
    )
    "" | Out-File $File -Encoding ASCII
}

# Function to split a file by line number
function Split-FileByLineNr {
    [CmdletBinding()]
    Param (
	[Parameter(Mandatory)]
	[string]$PathName,
	[Parameter(Mandatory)]
	[string]$OutputFilenamePattern,
	[Parameter(Mandatory)]
	[int]$LineLimit
    )
    $input = Get-Content -Path $PathName
    $line = 0
    $i = 0
    $path = 0
    $start = 0
    while ($line -le $input.Length) {
	if ($i -eq $LineLimit -Or $line -eq $input.Length) {
	    $path++
	    $pathname = "$OutputFilenamePattern$path.csv"
	    $input[$start..($line - 1)] | Out-File $pathname -Force
	    $start = $line
	    $i = 0
	    Write-Host "$pathname"
	}
	$i++
	$line++
    }
}

# Function to split a file by regex match
function Split-FileByMatch {
    [CmdletBinding()]
    Param (
	[Parameter(Mandatory)]
	[string]$PathName,
	[Parameter(Mandatory)]
	[string]$Regex
    )
    $ext = $PathName | Split-Path -Extension
    $parent = $PathName | Split-Path -Parent
    $OriginalName = $PathName | Split-Path -LeafBase
    $inputx = Get-Content -Path $PathName
    $line = 0
    $i = 0
    $start = @(Select-String -Path $PathName -Pattern $Regex) | Select-Object -ExpandProperty LineNumber
    $LineLimit = $start | Select-Object -Skip 1
    $names = @()
    [regex]::Matches($inputx, $Regex).Groups.Value | ForEach-Object { $names += $_ }
    $occurence = 0

    while ($line -le $inputx.Length) {
	if ($i -eq ([int]$LineLimit[$occurence].LineNumber - 1) -Or $line -eq $inputx.Length) {
	    $currentName = $names[$occurence]
	    $pathname = Join-Path -Path $parent -ChildPath "$OriginalName-$currentName$ext"
	    $u = ([int]$start[$occurence].LineNumber - 1)
	    $inputx[$u..($line - 1)] | Out-File $pathname
	    $occurence++
	    Write-Host "$u..($line - 1) $pathname"
	}
	$i++
	$line++
    }
}

# Check if 'trid' command exists before declaring related functions
if (Test-CommandExists 'trid') {
    # Function to set file extension based on 'trid' command output
    function Set-FileExtension {
	[CmdletBinding()]
	Param (
	    [Parameter(Mandatory)]
	    [string]$Location
	)
	Set-Location $Location
	$files = Get-ChildItem -File
	$total = $files.Count
		$current = 0
		$current = 0
		$current = 0

        $current = 0

	$current = 0
		$current = 0

        $current = 0

	$shell = $Host.UI.RawUI
	$shell.WindowTitle = "Progress 0% @ $Location"

	foreach ($file in $files) {
	    $current++
	    $percent = ($current / $total) * 100
	    $shell.WindowTitle = "Progress $percent% @ $Location"
	    Write-Progress -Activity "Setting file extensions in $Location" -Status "Processing file $current of $total" -PercentComplete $percent -CurrentOperation "Checking file '$($file.Name)'"
	    Set-FileExtensionIfNotMatch -FileName $file.Name
	}
    }

    # Helper function to set file extension if it does not match the expected one
    function Set-FileExtensionIfNotMatch {
	[CmdletBinding()]
	Param (
	    [Parameter(Mandatory)]
	    [string]$FileName
	)
	$currentExtension = [System.IO.Path]::GetExtension($FileName)
	$expectedExtension = Get-FileExtensionFromTrid -FileName $FileName

	if ($currentExtension -ne $expectedExtension) {
	    Rename-Item -Path $FileName -NewName ("$FileName$expectedExtension")
	    Write-Output "Renamed file '$FileName' to have extension '$expectedExtension'"
	}
    }

    # Helper function to get file extension from 'trid' command output
    function Get-FileExtensionFromTrid {
	[CmdletBinding()]
	Param (
	    [Parameter(Mandatory)]
	    [string]$FileName
	)
	$tridOutput = trid $FileName

	  if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	  if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	  if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	    # Get the highest percentage match and its corresponding extension
        if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	    # Get the highest percentage match and its corresponding extension
	if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	  if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	    # Get the highest percentage match and its corresponding extension
        if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	    # Get the highest percentage match and its corresponding extension
	    $highestMatch = ($tridOutput | Select-String "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)" -AllMatches).Matches | Select-Object -First 1
	    $extension = ($highestMatch.Groups[2].Value -split '/')[0]
	    return $extension
	} else {
	    return ""
	}
    }
}
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
	$sesStor = "$DriveLetter\sessionStorage\$childNode"
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
