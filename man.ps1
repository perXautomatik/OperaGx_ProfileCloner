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
    [string]$ProfileAlias = "a_taboo",
    [string]$DriveLetter = 'E:',
    [string]$Launcher = "$DriveLetter\OperaGXPortable\App\OperaGX\launcher.exe",
    [hashtable]$ProfileSpecific = @{}
)

# Begin block
Begin {

    # Set default values	
    # Override defaults with specific profile configurations if provided
	$ProfileConfig = @($ProfileSpecific[$ProfileAlias] , @{})| ?{ $null -ne $_}[0]


    $DefaultParameters = '--disable-usage-statistics-question --side-profile-minimal --with-feature:side-profiles --no-default-browser-check'
    $DefaultProfileFolderPath = Join-Path $DriveLetter "_side_profiles"
    $DefaultDownloadsPath = Join-Path $DriveLetter "downloads"
	$DefaultExtensionsToLoad = (Get-ChildItem -Path "$DriveLetter\crx").FullName
		
	$launchParams = @{
		Profile = $ProfileAlias
		Extensions = @($ProfileConfig['Extensions'] , $DefaultExtensionsToLoad)| ?{ $null -ne $_}[0]
		DownloadsPath = @($ProfileConfig['DownloadsPath'] , $DefaultDownloadsPath )| ?{ $null -ne $_}[0]
		DefaultParameters = @($ProfileConfig['Parameters'] , $DefaultParameters)| ?{ $null -ne $_}[0]
		ProfileFolderPath = @($ProfileConfig['ProfileFolderPath'] , $DefaultProfileFolderPath )| ?{ $null -ne $_}[0]
	}

	# Prepare launcher options
	$OperaLaunchParams = @{
		FilePath = $launcher
		ArgumentList = (Prepare-LauncherOptions @launchParams)
	}
	
	$DefaultPathSuffix = '\_side_profiles'
	$DefaultExcludedExtensions = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"
	
	$DefaultCopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')        
    $DefaultPreserve = @('Bookmarks', 'History', 'Bookmarks.bak', 'Web Data', 'Extension State', 'Cookies', 'Cache','Local Storage', 'Session Storage', 'Login Data', 'network', 'Local Extension Settings','Preferences')
    

	$CacheClearParams = @{
		childNode = $ProfileAlias
		driveLet = $DriveLetter
		pathSufix = @($ProfileConfig['PathSuffix'] , $DefaultPathSuffix)| ?{ $null -ne $_}[0]
		ExcludedExtensions = @($ProfileConfig['ExcludedExtensions'] , $DefaultExcludedExtensions)| ?{ $null -ne $_}[0]
	
		CopyToCache = @($ProfileConfig['CopyToCache'] , $DefaultCopyToCache)| ?{ $null -ne $_}[0]
		Preserve = @($ProfileConfig['Preserve'] , $DefaultPreserve)| ?{ $null -ne $_}[0]
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
			
			#invoke
			$ProgressParams.CurrentOperation = $ProcessBlock.Invoke($currentObject).ToString()
			$ProgressParams = HashKeys-ByFunction Write-Progress $ProgressParams;						
			# Display the progress bar using splatting
			Write-Progress @ProgressParams

			# Update the console title
			$shell.WindowTitle = "Progress $($ProgressParams.PercentComplete)%"
		}

		end {
			# Any cleanup code if needed
		}
	}


	function HashKeys-ByFunction {
		param (
			$commandName,
			$HashedParams
		)
			# Get the list of valid parameter names for the function
			$validParameters = (Get-Command $commandName).Parameters.Keys
			# Filter out invalid parameters
			$q = $HashedParams.Keys | ? { $_ -notin $validParameters } ;
			$q | % { $HashedParams.Remove($_) }

			return $HashedParams						
		}

	function Clear-Cache {
		[CmdletBinding()]
		param (
			[Alias("DriveLet")][string]$DriveLetter,
			[Alias("PathSufix")][string]$PathSuffix,
			[Alias("ProfileName")][string]$ChildNode,
			[string]$ExcludedExtensions,
			[string]$SessionStorage = "$DriveLetter\sessionStorage",	
			[string]$SourceFolder = (Join-Path -Path $DriveLetter -ChildPath $PathSuffix),
			[string]$ProfileLocation = (Join-Path -Path $SourceFolder -ChildPath $ChildNode)
		)

		begin 		
		{
		
			function Get-SessionId {
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


			function Move-BasedOnExtension {
				[CmdletBinding()]
				param (
					[Parameter(Mandatory = $true)] [string]$OriginalFolderPath,			
					[Parameter(Mandatory = $true)] [string]$ExcludedExtensions,			
					[Parameter(Mandatory = $true)] [string]$NewFolderPath
				)
			
			
				# Convert the excluded extensions string into an array
				$excludedExtensionArray = $ExcludedExtensions -split ","
			
							
				# Convert the excluded extensions string into an array
				$excludedExtensionArray = $ExcludedExtensions -split ","
			
				# Retrieve all files in the original folder path
				$files = Get-ChildItem -Path $OriginalFolderPath -File
								
				# Filter files to exclude the specified extensions
				$filesToMove = $files | Where-Object { $_.Extension -notin $ExcludedExtensions -split "," }
			
				# Check if there are files to move
				if ($filesToMove) {
					# Ensure the new folder path exists
					$null = New-Item -ItemType Directory -Force -Path $NewFolderPath
			
					# Move the filtered files
					foreach ($file in $filesToMove) {
						Move-Item -Path $file.FullName -Destination $NewFolderPath -PassThru
					}
			
					# Output the count of moved files
					Write-Verbose "$($filesToMove.Count) file(s) moved to $NewFolderPath"
				}
				else {
					Write-Host "No files to move based on the specified extensions."
				}
			}
			

			# Navigate to the source folder
			Push-Location
			Set-Location -Path $SourceFolder
			# Retrieve cache directories and process each one
			$toProcess = Get-ChildItem -Path $ProfileLocation -Depth 1 -Include "cache" | % {Get-ChildItem -Path $_.FullName  }		
		}
		
		process {
			$toProcess  | %{
				$currentCacheFolder = $_
				$parentProfileName = $currentCacheFolder.Parent.Name
				$newFolder = Join-Path -Path $SessionStorage -ChildPath (join-path $parentProfileName (Get-SessionId -ChildPath $currentCacheFolder))
			
				# Check if the new folder already exists
				if ((Get-ChildItem -Path $newFolder -ErrorAction SilentlyContinue).Length -gt 0) {
					Write-Debug "The folder already exists."
				} else {
					# Change file extensions before moving
					$currentCacheFolder.FullName | Set-FileExtension
		
					# Define parameters for moving files based on extension
					$moveParams = @{
						ExcludedExtension = $ExcludedExtensions
						OriginalFolderPath = $currentCacheFolder.FullName
						NewFolderPath = $newFolder
					}
		
					# Move files based on the defined parameters
					Move-BasedOnExtension @moveParams
				}	
		}

		end {
			# Return to the original location
			Pop-Location	
		}
	}
	}
    
	# Function to prepare launcher options
	function Prepare-LauncherOptions {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[alias("Profile")][string]$childNode,
			[Parameter()]
			[string[]]$Extensions,
			[Parameter(Mandatory)]
			[string]$DownloadsPath,
			[Parameter(Mandatory)]
			[string]$DefaultParameters,
			[Parameter(Mandatory)]
			[string]$ProfileFolderPath
		)

		$ProfileParam = '--side-profile-name="' + $childNode + '"'

		$ExtensionParam = if ($Extensions) { " --load-extension='" + ($Extensions -join ',') + "'" } else { "" }
		if (Test-Path $DownloadsPath)
		{$DownloadParam = " --download.default_directory='" + $DownloadsPath + "'"}

		$AllArgs = @($ProfileParam, $ExtensionParam, $DownloadParam, $DefaultParameters)
		Write-Verbose "Launcher arguments: $AllArgs"

		return $AllArgs
	}
}

# Process block
Process {
	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams)
    
	Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $driveLetter"

    Set-Location $driveLetter
    Set-Location $driveLetter
    Set-Location $driveLetter
    Set-Location $driveLetter
	
    Set-Location $driveLetter	
	
    Set-Location $driveLetter	
    Set-Location $driveLetter
	
    Set-Location $driveLetter	
	
    Set-Location $driveLetter	
    Set-Location $driveLetter
    Set-Location $driveLetter
	
    Set-Location $driveLetter	
	
    Set-Location $driveLetter	
    Set-Location $driveLetter
	
    Set-Location $driveLetter	
	

	Write-Verbose "Process options: $OperaLaunchParams"

	Start-Process @OperaLaunchParams -Wait 
}

# End block
End {
    & $driveLetter\OperaLauncher\PurgeProfile.ps1 @CacheClearParams

	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams)
}
