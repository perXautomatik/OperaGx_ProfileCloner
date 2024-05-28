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
	    $highestMatch = ($tridOutput | Select-String "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)" -AllMatches).Matches | Select-Object -First 1
	    $extension = ($highestMatch.Groups[2].Value -split '/')[0]
	    return $extension
	} else {
	    return ""
	}
    }
}

# Function to set file extension through piping
function Set-FileExtensionThroughPiping {
    <#
    .SYNOPSIS
    Sets the file extension for files in the specified path through piping.

    .DESCRIPTION
    This function sets the file extension for each file in the provided path.
    It uses piping to process multiple files and updates the console title with progress.

    .PARAMETER Path
    The path where the files are located.

    .EXAMPLE
    'C:\Files' | Set-FileExtensionThroughPiping
    #>
    [CmdletBinding()]
    param (
	[Parameter(ValueFromPipeline = $true)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({
	    if ($_.psobject.Methods.Match('ToString')) {
		$true
	    } else {
		throw 'Cannot convert pipeline object to string!'
	    }
	})]
	[string]$Path
    )

    Process {
	Set-Location $Path
	$files = Get-ChildItem -File
	$total = $files.Count
	$current = 0
	$shell = $Host.UI.RawUI
	$shell.WindowTitle = "Progress 0% @ $Path"

	foreach ($file in $files) {
	    $current++
	    $percent = ($current / $total) * 100
	    $shell.WindowTitle = "Progress $percent% @ $Path"
	    Write-Progress -Activity "Setting file extensions in $Path" -Status "Processing file $current of $total" -PercentComplete $percent -CurrentOperation "Checking file '$($file.Name)'"
	    Set-FileExtensionIfNotMatch -FileName $file.Name
	}
    }
}
