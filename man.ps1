<#
.SYNOPSIS
This script launches the Opera browser with a specified profile and manages the cache.

.DESCRIPTION
The script imports necessary modules, launches Opera with the given profile, and performs cache management tasks before and after the profile launch.

.PARAMETER ProfileAlias
The alias of the profile to launch.

.PARAMETER DriveLetter
The drive letter where Opera is installed.

.PARAMETER LauncherPath
The path to the Opera launcher executable.

.PARAMETER ProfileSpecific
A hashtable containing specific configurations for profiles.

.EXAMPLE
.\LaunchOperaProfile.ps1 -ProfileAlias 'a_jap' -ProfileSpecific @{ 'a_jap' = @{ 'Extensions' = @('path\to\extension1', 'path\to\extension2'); 'DownloadsPath' = 'E:\Downloads' } }
#>

# Define parameters
[CmdletBinding()]
param (
    [Alias("ChildNode")]
    [string]$ProfileAlias = "a_vin",
    [string]$DriveLetter = 'E:',
    [string]$Launcher = "$DriveLetter\OperaGXPortable\App\OperaGX\launcher.exe",
    [hashtable]$ProfileSpecific = @{}
)

# Begin block
Begin {


import-module ".\lib\FileHelper.psm1"
    Import-Module ".\moveOutOfCache.ps1"

    # Set default values
    $DefaultDownloadsPath = Join-Path $DriveLetter "downloads"
    $DefaultProfileFolderPath = Join-Path $DriveLetter "_side_profiles"
    $DefaultParameters = '--disable-usage-statistics-question --side-profile-minimal --with-feature:side-profiles --no-default-browser-check'
    $DefaultPathSuffix = '\_side_profiles'
    $DefaultCopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')
    $DefaultPreserve = @('Bookmarks', 'History', 'Bookmarks.bak', 'Web Data', 'Extension State', 'Cookies', 'Cache','Local Storage', 'Session Storage', 'Login Data', 'network', 'Local Extension Settings','Preferences')

    $DefaultExcludedExtensions = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"

    # Override defaults with specific profile configurations if provided

    $ProfileConfig = @($ProfileSpecific[$ProfileAlias] , @{})| ?{ $null -ne $_}[0]
    $DownloadsPath = @($ProfileConfig['DownloadsPath'] , $DefaultDownloadsPath )| ?{ $null -ne $_}[0]
    $ProfileFolderPath = @($ProfileConfig['ProfileFolderPath'] , $DefaultProfileFolderPath    )| ?{ $null -ne $_}[0]
    $CopyToCache = @($ProfileConfig['CopyToCache'] , $DefaultCopyToCache)| ?{ $null -ne $_}[0]
    $Preserve = @($ProfileConfig['Preserve'] , $DefaultPreserve)| ?{ $null -ne $_}[0]
	$ExtensionsToLoad = @($ProfileConfig['Extensions'] , (Get-ChildItem -Path "$DriveLetter\crx").FullName)| ?{ $null -ne $_}[0]
	$Parameters = @($ProfileConfig['Parameters'] , $DefaultParameters)| ?{ $null -ne $_}[0]
    $PathSuffix = @($ProfileConfig['PathSuffix'] , $DefaultPathSuffix)| ?{ $null -ne $_}[0]
    $ExcludedExtensions = @($ProfileConfig['ExcludedExtensions'] , $DefaultExcludedExtensions)| ?{ $null -ne $_}[0]

	$paramx = @{
		driveLet = $DriveLetter
		pathSufix = $PathSuffix
		childNode = $ProfileAlias
	}


	$launchParams = @{
		Profile = $ProfileAlias
		Extensions = $ExtensionsToLoad
		DownloadsPath = $DownloadsPath
		DefaultParameters = $Parameters
		ProfileFolderPath = $ProfileFolderPath
	}

	# Function to prepare launcher options
	function Prepare-LauncherOptions {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[string]$Profile,
			[Parameter()]
			[string[]]$Extensions,
			[Parameter(Mandatory)]
			[string]$DownloadsPath,
			[Parameter(Mandatory)]
			[string]$DefaultParameters,
			[Parameter(Mandatory)]
			[string]$ProfileFolderPath
		)

		$ProfileParam = '--side-profile-name="' + $Profile + '"'

		$ExtensionParam = if ($Extensions) { " --load-extension='" + ($Extensions -join ',') + "'" } else { "" }
		if (Test-Path $DownloadsPath)
		{$DownloadParam = " --download.default_directory='" + $DownloadsPath + "'"}

		$AllArgs = @($ProfileParam, $ExtensionParam, $DownloadParam, $DefaultParameters)
		Write-Verbose "Launcher arguments: $AllArgs"

		return $AllArgs
	}

	# Function to launch the process
	function Invoke-LaunchProcess {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[string]$FilePath,
			[Parameter(Mandatory)]
			[string[]]$ArgumentList
		)

		$ProcessOptions = @{
			FilePath     = $FilePath
			ArgumentList = $ArgumentList
		}
		Write-Verbose "Process options: $ProcessOptions"

		Start-Process @ProcessOptions -Wait
	}


	function SetFileExtensionThroughPiping {
		[CmdletBinding()]
		param (
			[Parameter(ValueFromPipeline = $true,Mandatory = $true)]
			[ValidateNotNullOrEmpty()]
			[ValidateScript({				
				if($_.length -gt 0) { $true }
				else { throw 'empty string or zero length array provided' }
			})]
			$InputObject
		)

		begin {
			foreach ($item in $InputObject) {
				# Determine if the input is a file or directory
				if (Test-Path $item -PathType Leaf) {
					# It's a file, add to processing list
					$files += Get-Item $item
				} elseif (Test-Path $item -PathType Container) {
					# It's a directory, add all files within to processing list
					$files += Get-ChildItem $item -File
				}
			}

			# Define the progress parameters
			$ProgressParams = @{
				TotalCount = $files.Count
				ActivityTitle = "Setting file extensions"
				Status = ""
				PercentComplete = 0
				CurrentOperation = ""
			}

		}
		process {

			# Process each file with the progress bar
			$files | Process-WithProgressBar -ProcessBlock {
				param($file)
				# Your processing code here
				Set-FileExtensionIfNotMatch $file.FullName
			} -ProgressParams $ProgressParams

		}

		end {
			# Any cleanup code if needed
		}
	}

	function Process-WithProgressBar {
		[CmdletBinding()]
		param (
			[parameter(ValueFromPipeline)]
			$_,
			[Parameter(Mandatory = $true)]
			[scriptblock]$ProcessBlock,
			[Parameter(Mandatory = $true)]
			[hashtable]$ProgressParams
		)

		begin {
			# Initialize variables that are used in the process block
			$current = 0
			$total = $ProgressParams.TotalCount
			$shell = $Host.UI.RawUI
		}

		process {
			# Process the current piped object
			$currentObject = $_

			# Increment the current count
			$current++

			# Calculate the percentage of completion
			$percent = ($current / $total) * 100

			# Update the progress parameters
			$ProgressParams.PercentComplete = $percent
			$ProgressParams.Status = "Processing item $current of $total"
			$ProgressParams.CurrentOperation = $ProcessBlock.Invoke($currentObject).ToString()

			# Display the progress bar using splatting
			Write-Progress @ProgressParams

			# Update the console title
			$shell.WindowTitle = "Progress $($ProgressParams.PercentComplete)%"
		}

		end {
			# Any cleanup code if needed
		}
	}





function Launch_opera_profile {

	# Prepare launcher options
    $AllArgs = Prepare-LauncherOptions @launchParams

    $processOptions = @{
	FilePath = $launcher
	ArgumentList = $AllArgs
    }; echo $processOptions

    # Launch the Opera profile
    Invoke-LaunchProcess @processOptions
}

    function moveBasedONextnesion() {
	[CmdletBinding()]
	param (
	    $originalFolderPath,
	    $excludedExtension,
	    $newFolderPath
	)
	    $exect = @($excludedExtension -split "," );

	    $unfiltered = (Get-ChildItem -Path $originalFolderPath -File)
	    $withExtensions = $unfiltered | ? { $_.Extension };
	    $filteredToMove = $withExtensions | ? { $_.Extension -notin $exect };
	    $zz = $filteredToMove.Length;
	    $z = [bool]$zz -gt 0;

	    if ( $z ){


		New-Item -ItemType Directory -Force -Path $newFolderPath ;

		$filteredToMove | % {  Move-Item -Path $_.FullName -Destination $newFolderPath -PassThru  }
		Write-Host (""+($filteredToMove.Length)+ "/" + ($newFolderPath | get-childitem).length)
	    }
	    else {
		Write-Host "no cache"
	    }
    }

    function get-sesId {
		param(
			$childPath
		)

		$internalItems = ($childPath | get-childitem );
		$firtFile = (($internalItems | Sort-Object CreationTime | Select-Object -First 1).CreationTime);
		$lastFile = (($internalItems | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime);
		$q = $lastFile -$firtFile

		if($q.Days -gt 0)
		{
			$from = get-date -date $firtFile  -Format "yyMMdd_HHmmss"
			$to = get-date -date $lastFile  -Format "yyMMdd_HHmmss"
		}

		$sessionId = (Get-Date -Format "yyMMdd_HHmmss");
		return $sessionId;
    }

    function clearCache() {

		[CmdletBinding()]
		param (
			[alias("driveLet")]$driveLetter = "E:",
			$pathSufix = "\_side_profiles",
			[alias("profileName")]$childNode, # = "a_vin"
			$sourceFold = (join-path $driveLetter $pathSufix),
			$profileLocation = (join-path $sourceFold $childNode),
			$sessionStorage = "$driveLetter\sessionStorage",
			$exc = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"
		)

		Push-Location;
		cd $sourceFold;

		$unfiltered = @((get-childitem -Path $profileLocation -dept 1 -include "cache") | get-childitem ) ;
		$unfiltered | % {
			$childNode = $_.parent.parent

			$sesStor = "$driveLetter\sessionStorage\$childNode"

			$sessionId = get-sesId -childPath $childNode;

			$newFol = (Join-Path ($sesStor) $sessionId)
			if (($newFol | Get-ChildItem -ErrorAction SilentlyContinue).Length -gt 0 ) {
			Write-Debug "already exsisting"
			}
			else
			{
			( $_.fullname | SetFileExtensionThroughPiping ) ;
			moveBasedONextnesion -excludedExtension $exc -originalFolderPath $_.fullname -newFolderPath $newFol
			}

		}

		Pop-Location;

    }

    clearCache @paramx

}

# Process block
Process {
    Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $driveLet"

    Set-Location $driveLet\
	Launch_opera_profile -a $childNode
}

# End block
End {
    & $driveLetter\OperaLauncher\PurgeProfile.ps1 @paramx -CopyToCache $copyToCache -preserve $preserve

	clearCache @paramx
}
