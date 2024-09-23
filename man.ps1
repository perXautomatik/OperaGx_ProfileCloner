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
.\LaunchOperaProfile.ps1 -ProfileAlias 'a_jap' -ProfileSpecific @{ 'a_jap' = @{ 'Extensions' = @('path\to\extension1', 'path\to\extension2'); 'DownloadsPath' = '$DriveLetter\Downloads' } }

.todo
    -fix extension loading to also include last and first extension
    -include activity watch renaming
    -multithread file renaming, maybe separate process identifiying the new name, then utelize some trix to rename faster on ntfs harddrives
    -deduce session age by assuming that it can not range than more than a few hours, and that it probably is represented by the majority of the files present
    -allow usage with firefox profiles
    -make sure visual bookmarks extens state is kept (make sure to only copy relevant files on session capture, not to move or rename them)
    -backup by moving session first to another drive with guranteed space, then delete with recyclebin, then move back in place 
    -allow ongoing cachfolder moving process during browser running
        -watch process of ongoing cache moving as a taskbar progressbar
        -allow ongoing or manual move of cache
        -allow locking of files in cache folder, refusing changes or deleting from the browser
        -utelzie program to stich togeter ts files from browser folder
    - use git to monitor changes in profile settings, bookmarks, cookies and history, but not as blobs
    - failsafe in case no space left on hd, preferably some sort of stop all, or stop all unsafe actions
    - allow backup of browser sessions by encapsulating relevant files, (through git etc) (requires a major restructure of everything)
    - specify extensions to load by simply calling them by name, not requiring exact path
    - get download location to work (currently sets to system default)
    - integrate with browser wrangler (br) (for example open correct profile for content deemed more suitable for such etc)
    - create session summary, like time total of session, tabs opened, bookmarks saved, time spent on each tab, 
    - allow session migration between chromium based browser and mozilla based browsers
    - allow session migration between current browser and legazy browsers
    - activity watch catigorization based on activity watch category json file
    - taggui integration, runnign after session is concluded on renamed session folder, or list of folders
    - start profile loading and simmilar as its own task freeing up console if more profiles need to be loaded.

    #>
# Define parameters
[CmdletBinding()]
param (
    [Alias("ChildNode")]
    [string]$ProfileAlias = "a_mat",
    [string]$DriveLetter = 'H:',
    [hashtable]$ProfileSpecific = @{ 'a_toon' = @{ 'Extensions' = @(
		#"$DriveLetter\crx\Auto-Tab-Discard-suspend.crx",
		#"$DriveLetter\crx\downloadhelper_8_2_0_20.crx",
		"$DriveLetter\crx\Folderwise-Bookmarks-Search-Sessions.crx",
		"$DriveLetter\crx\I-don-t-care-about-cookies.crx",
		"$DriveLetter\crx\ImageAssistant-Batch-Image-Downloader.crx",
		"$DriveLetter\crx\Image-downloader-Imageye.crx",
		"$DriveLetter\crx\ImageSearchAssistant_2_0_9_0.crx",
		#"$DriveLetter\crx\Immersive Translate webpage_1_2_1_0.crx",
		"$DriveLetter\crx\Load-Background-Tabs-Lazily.crx",
		"$DriveLetter\crx\uAutoPagerize.crx",
		"$DriveLetter\crx\VisualBookmarks_5_12_2_0.crx",
		"$DriveLetter\crx\activityWatch_0_4_3_0.crx"
		
		); 'DownloadsPath' = '$DriveLetter\Downloads' }; 
    'a_bust' = @{ 'Extensions' = @(
		"$DriveLetter\crx\Auto-Tab-Discard-suspend.crx",
		"$DriveLetter\crx\downloadhelper_8_2_0_20.crx",
		"$DriveLetter\crx\Folderwise-Bookmarks-Search-Sessions.crx",
		"$DriveLetter\crx\I-don-t-care-about-cookies.crx",
		#"$DriveLetter\crx\ImageAssistant-Batch-Image-Downloader.crx",
		#"$DriveLetter\crx\Image-downloader-Imageye.crx",
		#"$DriveLetter\crx\ImageSearchAssistant_2_0_9_0.crx",
		#"$DriveLetter\crx\Immersive Translate webpage_1_2_1_0.crx",
		"$DriveLetter\crx\Load-Background-Tabs-Lazily.crx",
		"$DriveLetter\crx\uAutoPagerize.crx",
		"$DriveLetter\crx\VisualBookmarks_5_12_2_0.crx",
		"$DriveLetter\crx\activityWatch_0_4_3_0.crx"
		
		) }; 
    'a_wif' = @{ 'Extensions' = @(
		"$DriveLetter\crx\Auto-Tab-Discard-suspend.crx",
		"$DriveLetter\crx\downloadhelper_8_2_0_20.crx",
		"$DriveLetter\crx\Folderwise-Bookmarks-Search-Sessions.crx",
		#"$DriveLetter\crx\I-don-t-care-about-cookies.crx",
		#"$DriveLetter\crx\ImageAssistant-Batch-Image-Downloader.crx",
		#"$DriveLetter\crx\Image-downloader-Imageye.crx",
		#"$DriveLetter\crx\ImageSearchAssistant_2_0_9_0.crx",
		#"$DriveLetter\crx\Immersive Translate webpage_1_2_1_0.crx",
		#"$DriveLetter\crx\Load-Background-Tabs-Lazily.crx",
		#"$DriveLetter\crx\uAutoPagerize.crx",
        "$DriveLetter\crx\ExportSelectiveBookmarks_1_1_0_0.crx",
		"$DriveLetter\crx\VisualBookmarks_5_12_2_0.crx",
		"$DriveLetter\crx\activityWatch_0_4_3_0.crx"		
		) };
    'a_afr' = @{ 'Extensions' = @(
		"$DriveLetter\crx\Auto-Tab-Discard-suspend.crx",
		"$DriveLetter\crx\downloadhelper_8_2_0_20.crx",
		"$DriveLetter\crx\Folderwise-Bookmarks-Search-Sessions.crx",
		#"$DriveLetter\crx\I-don-t-care-about-cookies.crx",
		#"$DriveLetter\crx\ImageAssistant-Batch-Image-Downloader.crx",
		"$DriveLetter\crx\Image-downloader-Imageye.crx",
		#"$DriveLetter\crx\ImageSearchAssistant_2_0_9_0.crx",
		#"$DriveLetter\crx\Immersive Translate webpage_1_2_1_0.crx",
		#"$DriveLetter\crx\Load-Background-Tabs-Lazily.crx",
		#"$DriveLetter\crx\uAutoPagerize.crx",
        "$DriveLetter\crx\ExportSelectiveBookmarks_1_1_0_0.crx",
		"$DriveLetter\crx\VisualBookmarks_5_12_2_0.crx",
		"$DriveLetter\crx\activityWatch_0_4_3_0.crx"		
		) }; 
    'a_mat' = @{ 'Extensions' = @(
		"$DriveLetter\crx\downloadhelper_8_2_0_20.crx",
		"$DriveLetter\crx\Folderwise-Bookmarks-Search-Sessions.crx",
		#"$DriveLetter\crx\I-don-t-care-about-cookies.crx",
		#"$DriveLetter\crx\ImageAssistant-Batch-Image-Downloader.crx",
		#"$DriveLetter\crx\Image-downloader-Imageye.crx",
		#"$DriveLetter\crx\ImageSearchAssistant_2_0_9_0.crx",
		#"$DriveLetter\crx\Immersive Translate webpage_1_2_1_0.crx",
		#"$DriveLetter\crx\Load-Background-Tabs-Lazily.crx",
		#"$DriveLetter\crx\uAutoPagerize.crx",
		"$DriveLetter\crx\VisualBookmarks_5_12_2_0.crx",
		"$DriveLetter\crx\activityWatch_0_4_3_0.crx",
"$DriveLetter\crx\Auto-Tab-Discard-suspend.crx"
		) }; 
    'a_ana' = @{ 'Extensions' = @(
		"$DriveLetter\crx\downloadhelper_8_2_0_20.crx",
		"$DriveLetter\crx\Folderwise-Bookmarks-Search-Sessions.crx",
		#"$DriveLetter\crx\I-don-t-care-about-cookies.crx",
		#"$DriveLetter\crx\ImageAssistant-Batch-Image-Downloader.crx",
		#"$DriveLetter\crx\Image-downloader-Imageye.crx",
		#"$DriveLetter\crx\ImageSearchAssistant_2_0_9_0.crx",
		#"$DriveLetter\crx\Immersive Translate webpage_1_2_1_0.crx",
		"$DriveLetter\crx\Load-Background-Tabs-Lazily.crx",
		#"$DriveLetter\crx\uAutoPagerize.crx",
		"$DriveLetter\crx\VisualBookmarks_5_12_2_0.crx",
"$DriveLetter\crx\Auto-Tab-Discard-suspend.crx",
		"$DriveLetter\crx\activityWatch_0_4_3_0.crx"
		) }},
    $basePath = 	"$DriveLetter\OperaLauncher",
    $configPath = 	"$basePath\config.json",
    [string]$Launcher = "$DriveLetter\OperaGXPortable\App\OperaGX\launcher.exe"
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
		Extensions = (Get-ChildItem -Path "$DriveLetter\crx").FullName
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
		  [hashtable] $ProfileConfig,
		  [array]$keys
		)
		
		$mergedConfig = @{}
		$filteredConfigs = @{}
    if ($profileConfig.Count -gt 0) {
		$mergedConfig = $ProfileConfig.Clone()
		$notInProfile = $DefaultConfig.GetEnumerator().Where( {!($_.Key -in $ProfileConfig.Keys)} )
		
		$notInProfile.ForEach({$mergedConfig[$_.key]=$_.Value })

		
		$mergedConfig.GetEnumerator().Where({$_.Key -in $keys}).ForEach({$filteredConfigs[$_.key]=$_.Value })

    } else {
        $filteredConfig = $defaultSettings.Clone()
    }
		return $filteredConfigs
	  }

	$launchParams = @{
		Profile = $ProfileAlias
	}

	$launchParams += Combine-ProfileConfig -DefaultConfig $Default -ProfileConfig $ProfileConfig -keys extensions,downloadspath,Parameters




    $cacheClearParams = @{
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
			$AllArgs +=$inputParams.Parameters

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
function Monitor-DiskSpace {
    param (
        [string]$DriveLetter,
        [int]$ThresholdMB
    )
    while ($true) {
        $freeSpaceMB = (Get-PSDrive -Name $DriveLetter).Free / 1MB
        if ($freeSpaceMB -lt $ThresholdMB) {
            Write-Warning "Warning: Free space on drive $DriveLetter is below $ThresholdMB MB. Current free space: $freeSpaceMB MB."
        }
        Start-Sleep -Seconds 5
    }
}
	
}

# Process block
Process {
    try {
        if (-not $cacheClearParams) {
            throw "Missing parameters for Clear-Cache."
        }
        $initialFreeSpace = (Get-PSDrive -Name $DriveLetter).Free
        if ($initialFreeSpace -lt 1GB) {
            throw "Insufficient initial disk space. At least 1GB free space is required."
        }
        $diskSpaceJob = Start-Job -ScriptBlock {
            param ($DriveLetter, $ThresholdMB)
            Monitor-DiskSpace -DriveLetter $DriveLetter -ThresholdMB $ThresholdMB
        } -ArgumentList $DriveLetter, 1024
        try {
            $filteredHash = Filter-ValidParameters "Clear-Cache" $cacheClearParams
        } catch {
            Write-Error "Failed to filter valid parameters: $_"
            throw
        }

        # Execute Clear-Cache
        try {
	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams) -ErrorAction Stop
        } catch {
            Write-Error "Clear-Cache failed: $_"
            throw
        }

	Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $driveLetter"
        try {
    Set-Location $driveLetter	
        } catch {
            Write-Error "Failed to set location to $DriveLetter: $_"
            throw
        }

	Write-Verbose "Process options: $OperaLaunchParams"
        try {
	Start-Process @OperaLaunchParams -Wait 
        } catch {
            Write-Error "Failed to start OperaLauncher: $_"
            throw
        }
        Stop-Job -Job $diskSpaceJob
        Remove-Job -Job $diskSpaceJob
    } catch {
        Write-Error "Process block failed: $_"
        throw
    }
}

# End block
End {
    try {
        try {
    & $global:purgeProfilePath @CacheClearParams
        } catch {
            Write-Error "Failed to execute purge profile script: $_"
            throw
        }

        try {
	Clear-Cache (HashKeys-ByFunction "Clear-Cache" $CacheClearParams) -ErrorAction Stop
        } catch {
            Write-Error "Clear-Cache in End block failed: $_"
            throw
        }
    } catch {
        Write-Error "End block failed: $_"
        throw
    }
}
