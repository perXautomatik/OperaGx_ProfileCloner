
# Define global parameters
param(
    [string]$profileAlias = 'a_jap',
    [string]$profileFolderPath = "$pwd\OperaGXPortable\App\OperaGX\profile\data\_side_profiles\",
    [bool]$renameProfile = $true,
    [string]$operaType = "portable",
    [bool]$isProfileInProfileFolder = $true,
    [bool]$shouldRenameAfter = !($profileAlias -match 'a_') -or $renameProfile,
    [bool]$shouldCloneIfEmpty = $true,
    [string]$downloadsPath = (Join-Path $pwd "downloads"),
    [string]$defaultParameters =
		'--disable-usage-statistics-question' +
		' --side-profile-minimal' +
		' --with-feature:side-profiles' +
		' --no-default-browser-check' +
		" --download.default_directory=$dls"
		,
    [string[]]$extensionsToLoad = (Get-ChildItem -Path "$pwd\crx").FullName,
    [string]$launcherPath = ".\OperaGXPortable\App\OperaGX\launcher.exe"
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
    Launch-OperaProfile -ProfileAlias 'a_jap' -Extensions $extensionsToLoad
    #>
    [CmdletBinding()]
    param (
	[Parameter(Mandatory)]
	[string]$ProfileAlias,
	[Parameter()]
	[string[]]$Extensions
    )

    $profilePath = if ($isProfileInProfileFolder) { Join-Path -Path $profileFolderPath -Child $ProfileAlias } else { $ProfileAlias }
    $profileParam = '--side-profile-name="' + $profilePath + '"'
    $extensionParam = if ($Extensions) { " --load-extension='" + ($Extensions -join ',') + "'" } else { "" }
    $allArgs = @($profileParam, $defaultParameters, $extensionParam)
    $processOptions = @{
	FilePath = $launcherPath
	ArgumentList = $allArgs
    }

    Start-Process @processOptions -Wait
    return (($profileFolderPath + $ProfileAlias + "\Cache\Cache_Data") -replace '\\', '\')
}


    $childNode = "a_wif" ;
    $driveLet = 'E:';
    $pathSufix = '\_side_profiles'
    $scriptLoc = '\OperaLauncher'
    [array]$excludedExtensions = @(".pam", ".zip", ".tar")

    clearCache -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode

    Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $driveLet"

    Set-Location $driveLet\; Launch-OperaProfile -a $childNode
$copyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob','Sessions')
$preserve =  @('Bookmarks'
,'History'
,'Bookmarks.bak'
,'Web Data','Extension State'
,'Cookies','Cache')

    & .\OperaLauncher\PurgeProfile.ps1 -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode -CopyToCache $copyToCache -preserve $preserve

    clearCache -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode