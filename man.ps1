<#
.SYNOPSIS
This script launches the Opera browser with a specified profile and manages the cache.

.DESCRIPTION
The script imports necessary modules, launches Opera with the given profile, and performs cache management tasks before and after the profile launch.

.PARAMETER ProfileAlias
The alias of the profile to launch.

.PARAMETER ProfileFolderPath
The path to the profile folder.

.PARAMETER DownloadsPath
The path to the downloads folder.

.PARAMETER ExtensionsToLoad
An array of extensions to load with the profile.

.PARAMETER LauncherPath
The path to the Opera launcher executable.

.EXAMPLE
.\LaunchOperaProfile.ps1 -ProfileAlias 'a_jap'
#>

# Define parameters
    [CmdletBinding()]
    param (
	[alias("ChildNode")][string]$ProfileAlias = "a_jap",
    [string]$DriveLetter = 'E:',
    
    [string]$LauncherPath = ".\OperaGXPortable\App\OperaGX\launcher.exe"
)

# Begin block
Begin {
    # Import required module
    Import-Module ".\lib\FileHelper.psm1"
	[string]$DownloadsPath = (Join-Path $driveLetter "downloads")
    # Define additional variables
    [string]$DefaultParameters =
		'--disable-usage-statistics-question' +
		' --side-profile-minimal' +
		' --with-feature:side-profiles' +
		' --no-default-browser-check' +
		" --download.default_directory=$DownloadsPath"
		,    
	$exc = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"
    $PathSuffix = '\_side_profiles'
    $CopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')
    $Preserve = @('Bookmarks', 'History', 'Bookmarks.bak', 'Web Data', 'Extension State', 'Cookies', 'Cache')
	[string[]]$ExtensionsToLoad = (Get-ChildItem -Path "$driveLetter\crx").FullName
	[string]$ProfileFolderPath = "$driveLetter\OperaGXPortable\App\OperaGX\profile\data\_side_profiles\"
    

# Function to launch Opera with a specified profile
function Launch-OperaProfile {
    <#
    .SYNOPSIS
    Launches Opera browser with the specified profile.

    .DESCRIPTION
    This function starts the Opera browser with the given profile and extensions.

    .PARAMETER ProfileAlias
    The alias of the profile to launch.

    .PARAMETER Extensions
    An array of extensions to load with the profile.

    .EXAMPLE
    Launch-OperaProfile -ProfileAlias 'a_jap' -Extensions $ExtensionsToLoad
    #>
    [CmdletBinding()]
    param (
	[Parameter(Mandatory)]
	[string]$ProfileAlias,
	[Parameter()]
	[string[]]$Extensions, $DefaultParameters
    )

    $profilePath = if ($IsProfileInProfileFolder) { Join-Path -Path $ProfileFolderPath -Child $ProfileAlias } else { $ProfileAlias }
    $profileParam = '--side-profile-name="' + $profilePath + '"'
    $extensionParam = if ($Extensions) { " --load-extension='" + ($Extensions -join ',') + "'" } else { "" }
    $allArgs = @($profileParam, $DefaultParameters, $extensionParam)
    $processOptions = @{
	FilePath = $LauncherPath
	ArgumentList = $allArgs
    }

    Start-Process @processOptions -Wait
    Write-Verbose (($ProfileFolderPath + $ProfileAlias + "\Cache\Cache_Data") -replace '\\', '\')
}

}

# Process block
Process {
    # Clear cache before launching the profile
    Clear-Cache -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ProfileAlias -ExcludedExtension $exc

    Write-Verbose "Invoking OperaLauncher with parameter $ProfileAlias on drive $DriveLetter"

    # Launch the Opera profile
    Set-Location $DriveLetter
    Launch-OperaProfile -ProfileAlias $ProfileAlias -Extensions $ExtensionsToLoad
}

# End block
End {
    # Purge profile and manage cache
    & $pwd\PurgeProfile.ps1 -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ChildNode -CopyToCache $CopyToCache -Preserve $Preserve

    # Clear cache after profile purge
    Clear-Cache -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ChildNode
}
