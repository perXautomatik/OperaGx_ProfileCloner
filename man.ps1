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

    # Set default values	
    # Override defaults with specific profile configurations if provided
	$ProfileConfig = @($ProfileSpecific[$ProfileAlias] , @{})| ?{ $null -ne $_}[0]

	Push-Location 
	cd $DriveLetter
	$global:setFilextPath = (Resolve-Path -Relative -path "./Set-FileExtensions.ps1");
	Pop-Location

	$Default = @{
		Parameters = '--disable-usage-statistics-question --side-profile-minimal --with-feature:side-profiles --no-default-browser-check'
		ProfileFolderPath = Join-Path $DriveLetter "_side_profiles"
		DownloadsPath = Join-Path $DriveLetter "downloads"
		ExtensionsToLoad = (Get-ChildItem -Path "$DriveLetter\crx").FullName
			
		PathSufix = '\_side_profiles'
		ExcludedExtensions = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"
		
		CopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')        
		Preserve = @('Bookmarks', 'History', 'Bookmarks.bak', 'Web Data', 'Extension State', 'Cookies', 'Cache','Local Storage', 'Session Storage', 'Login Data', 'network', 'Local Extension Settings','Preferences')
	}

	$launchParams = @{
		Profile = $ProfileAlias
		Extensions = @($ProfileConfig['Extensions'] , $Default.ExtensionsToLoad)| ?{ $null -ne $_}[0]
		DownloadsPath = @($ProfileConfig['DownloadsPath'] , $Default.DownloadsPath )| ?{ $null -ne $_}[0]
		DefaultParameters = @($ProfileConfig['Parameters'] , $Default.Parameters)| ?{ $null -ne $_}[0]		
	}

	$CacheClearParams = @{
		driveLet = $DriveLetter
		PathSufix = @($ProfileConfig['PathSufix'] , $Default.PathSufix)| ?{ $null -ne $_}[0]
		ChildNode = $ProfileAlias
		CopyToCache = @($ProfileConfig['CopyToCache'] , $Default.CopyToCache)| ?{ $null -ne $_}[0]
		Preserve = @($ProfileConfig['Preserve'] , $Default.Preserve)| ?{ $null -ne $_}[0]
		
		ExcludedExtensions = @($ProfileConfig['ExcludedExtensions'] , $Default.ExcludedExtensions)| ?{ $null -ne $_}[0]					
	}

    
	# Function to prepare launcher options
	function Prepare-LauncherOptions {
		[CmdletBinding()] param (	 [Parameter(Mandatory = $true)][hashtable]$inputParams )											
			$AllArgs = @() 
			$AllArgs += '--side-profile-name="' + $inputParams.Profile + '"'			
			if ($inputParams.Extensions) { $AllArgs += " --load-extension='" + ($inputParams.Extensions -join ',') + "'" } 			
			if ($inputParams.DownloadsPath) { $AllArgs += " --download.default_directory='" + $inputParams.DownloadsPath + "'"}
			$AllArgs +=$inputParams.DefaultParameters

			Write-Verbose "Launcher arguments: $AllArgs"

			return $AllArgs
	}
	
	# Prepare launcher options
	$OperaLaunchParams = @{
		FilePath = $launcher
		ArgumentList = (Prepare-LauncherOptions -inputParams $launchParams)
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
			$setFilext = $HashedParams.Keys | ? { $_ -notin $validParameters } ;
			$setFilext | % { $HashedParams.Remove($_) }

			return $HashedParams						
		}

	function Clear-Cache {
		[CmdletBinding()]
		param (
			$params,
			$driveLet,
			$PathSufix,
			$SourceFolder,
			$ChildNode,
			$ProfileFolderPath
		 )
		begin 		
		{
		
			$PreparedParams = @{
				SessionStorage = "$($params.DriveLet)\sessionStorage"
				SourceFolder = (Join-Path -Path $params.DriveLet -ChildPath $params.PathSufix)
				ProfileLocation = ""
			}

			$PreparedParams.ProfileLocation = 
			Join-Path -Path $PreparedParams.SourceFolder -ChildPath $params.ChildNode

			function Get-SessionId {
				param(
					$childPath
				)
		
				$internalItems = ($childPath | get-childitem );
				$firtFile = (($internalItems | Sort-Object CreationTime | Select-Object -First 1).CreationTime);
				$lastFile = (($internalItems | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime);
				$setFilext = $lastFile -$firtFile
		
				if($setFilext.Days -gt 0)
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
							
				# Retrieve all files in the original folder path
				$files = Get-ChildItem -Path $OriginalFolderPath -File
								
				# Filter files to exclude the specified extensions
				$filesToMove = $files | Where-Object { $_.Extension -notin $ExcludedExtensions -split "," }
			
				# Check if there are files to move
				if ($filesToMove) {
					# Ensure the new folder path exists
					$null = New-Item -ItemType Directory -Force -Path $NewFolderPath
					if (Test-Path $NewFolderPath) {
						# Move the filtered files
						foreach ($file in $filesToMove) {
							Move-Item -Path $file.FullName -Destination $NewFolderPath -PassThru
						}
				
						# Output the count of moved files
						Write-Verbose "$($filesToMove.Count) file(s) moved to $NewFolderPath"	
					}
					else {
						Write-Error "SessionFolder not created!"
						exit
					}
					
				}
				else {
					Write-Host "No files to move based on the specified extensions."
				}
			}
			

			# Navigate to the source folder
			#Push-Location
			#Set-Location -Path $SourceFolder
			# Retrieve cache directories and process each one
			$toProcess = Get-ChildItem -Path $PreparedParams.ProfileLocation -Depth 1 -Include "cache" | % {Get-ChildItem -Path $_.FullName  }		
		}
		process {
			$toProcess  | %{
				$currentFolder = $_
				$parentName = $currentFolder.Parent.Name
				$newFolder = Join-Path -Path $PreparedParams.SessionStorage -ChildPath (join-path $parentName (Get-SessionId -ChildPath $currentFolder))
			
				if ((Get-ChildItem $currentFolder -ErrorAction SilentlyContinue).Length -gt 0) {
					# Check if the new folder already exists
					if ((Get-ChildItem -Path $newFolder -ErrorAction SilentlyContinue).Length -gt 0) {
						Write-Debug "The folder already exists."
					} else {
						
						# Change file extensions before moving
						$currentFolder.FullName | & $global:setFilextPath

						# Define parameters for moving files based on extension
						$moveParams = @{
							ExcludedExtension = $ExcludedExtensions
							OriginalFolderPath = $currentFolder.FullName
							NewFolderPath = $newFolder
						}
						
						# Move files based on the defined parameters
						Move-BasedOnExtension @moveParams
					}	
				}
				else {
					Write-Debug "the folder is empty, skipping"
				}
				
			}
		}

		end {
			# Return to the original location
			Pop-Location	
		}
	}

}

# Process block
Process {
	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams)
    
	Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $driveLetter"

    Set-Location $driveLetter	

	Write-Verbose "Process options: $OperaLaunchParams"

	Start-Process @OperaLaunchParams -Wait 
}

# End block
End {
    & $driveLetter\OperaLauncher\PurgeProfile.ps1 @CacheClearParams

	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams)
}
