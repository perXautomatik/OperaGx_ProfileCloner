# Define global parameters
param(
    [string]$ProfileAlias = 'a_jap',
    [string]$ProfileFolderPath = "$pwd\OperaGXPortable\App\OperaGX\profile\data\_side_profiles\",
    [bool]$RenameProfile = $true,
    [string]$OperaType = "portable",
    [bool]$IsProfileInProfileFolder = $true,
    [bool]$ShouldRenameAfter = !($ProfileAlias -match 'a_') -or $RenameProfile,
    [bool]$ShouldCloneIfEmpty = $true,
    [string]$DownloadsPath = (Join-Path $pwd "downloads"),
    [string]$DefaultParameters =
		'--disable-usage-statistics-question' +
		' --side-profile-minimal' +
		' --with-feature:side-profiles' +
		' --no-default-browser-check' +
		" --download.default_directory=$dls"
		,
    [string[]]$ExtensionsToLoad = (Get-ChildItem -Path "$pwd\crx").FullName,
    [string]$LauncherPath = ".\OperaGXPortable\App\OperaGX\launcher.exe"
)

# Import required module
Import-Module ".\lib\FileHelper.psm1"

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
	[string[]]$Extensions
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
    return (($ProfileFolderPath + $ProfileAlias + "\Cache\Cache_Data") -replace '\\', '\')
}

# Main script execution
$ChildNode = "a_wif"
$DriveLetter = 'E:'
$PathSuffix = '\_side_profiles'

# Clear cache before launching the profile
Clear-Cache -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ChildNode

Write-Verbose "Invoking OperaLauncher with parameter $ChildNode on drive $DriveLetter"

# Launch the Opera profile
Set-Location $DriveLetter
Launch-OperaProfile -ProfileAlias $ChildNode

# Define paths for cache management
$CopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')
$Preserve =  @('Bookmarks'
,'History'
,'Bookmarks.bak'
,'Web Data','Extension State'
,'Cookies','Cache')

# Purge profile and manage cache
& .\OperaLauncher\PurgeProfile.ps1 -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ChildNode -CopyToCache $CopyToCache -Preserve $Preserve

# Clear cache after profile purge
Clear-Cache -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ChildNode
