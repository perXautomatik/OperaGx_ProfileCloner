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
    [string]$ProfileAlias = "a_wif",
    [string]$DriveLetter = 'E:',
    [string]$Launcher = "$DriveLetter\OperaGXPortable\App\OperaGX\launcher.exe",
    [hashtable]$ProfileSpecific = @{}
)

# Begin block
Begin {

    # Set default values	
    # Override defaults with specific profile configurations if provided
	$ProfileConfig = @($ProfileSpecific[$ProfileAlias] , @{})| ?{ $null -ne $_}[0]

	
	$global:setFilextPath = ("$driveLetter\OperaLauncher\Set-FileExtensions.ps1");
	$global:ClearCachePath = ("$driveLetter\OperaLauncher\Clear-Cache.ps1");
	$global:purgeProfilePath = ("$driveLetter\OperaLauncher\PurgeProfile.ps1");
	
	. $global:ClearCachePath

	$Default = @{
		Parameters = '--disable-usage-statistics-question --side-profile-minimal --with-feature:side-profiles --no-default-browser-check'
		ProfileFolderPath = Join-Path $DriveLetter "_side_profiles"
		DownloadsPath = Join-Path $DriveLetter "downloads"
		ExtensionsToLoad = (Get-ChildItem -Path "$DriveLetter\crx").FullName
		ExcludedFileNames = "data_0,data_1,data_2,data_3,indexs"
		PathSufix = '\_side_profiles'
		sessionStorage =  Join-Path $DriveLetter "sessionStorage"
		ExcludedExtensions = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"
		CopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')        
		Preserve = @('Bookmarks', 'History', 'Bookmarks.bak', 'Web Data', 'Extension State', 'Cookies', 'Cache','Local Storage', 'Session Storage', 'Login Data', 'network'
                                , 'Local Extension Settings'
                                #,'Preferences'
                                )
	}

function Combine-ProfileConfig {
  param (
    [Parameter(Mandatory=$true)]
    [hashtable] $DefaultConfig,
    [hashtable] $ProfileConfig
  )
  
  $mergedConfig = @{}
  $mergedConfig = $DefaultConfig.Clone()
  $mergedConfig += $ProfileConfig | Where-Object { $_.Key -ne $null }
  return $mergedConfig
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
		SessionStorage = @($ProfileConfig['sessionStorage'] , $Default.sessionStorage)| ?{ $null -ne $_}[0]
		ExcludedExtensions = @($ProfileConfig['ExcludedExtensions'] , $Default.ExcludedExtensions)| ?{ $null -ne $_}[0]					
		ExcludedFileNames = @($ProfileConfig['ExcludedFileNames'] , $Default.ExcludedFileNames)| ?{ $null -ne $_}[0]					
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

	
	function HashKeys-ByFunction {
		param (
			$commandName,
			$HashedParams
			)
		# Get the list of valid parameter names for the function
        $validParameters = (Get-Command $commandName).Parameters.Keys
        # Filter out invalid parameters
        $setFilext = $HashedParams.Keys | ? { $_ -notin $validParameters } ;
		$copiedHash = ([hashtable]$HashedParams).Clone()
        $setFilext | % { $copiedHash.Remove($_) }
        
        return $copiedHash						
    }
	
	# Prepare launcher options
	$OperaLaunchParams = @{
		FilePath = $launcher
		ArgumentList = (Prepare-LauncherOptions -inputParams $launchParams)
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
    & $global:purgeProfilePath @CacheClearParams

	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams)
}
