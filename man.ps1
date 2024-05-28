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

.EXAMPLE
.\LaunchOperaProfile.ps1 -ProfileAlias 'a_jap'
#>

# Define parameters
[CmdletBinding()]
param (
    [Alias("ChildNode")]
    [string]$ProfileAlias = "a_jap",
    [string]$DriveLetter = 'E:',
    [string]$LauncherPath = "$DriveLetter\OperaGXPortable\App\OperaGX\launcher.exe"
)

# Begin block
Begin {
    # Import required module
    Import-Module ".\lib\FileHelper.psm1"
	Import-Module ".\moveOutOfCache.ps1"

    # Define additional variables
    $DownloadsPath = Join-Path $DriveLetter "downloads"
    $ExtensionsToLoad = (Get-ChildItem -Path "$DriveLetter\crx").FullName
    $ProfileFolderPath = "$DriveLetter\OperaGXPortable\App\OperaGX\profile\data\_side_profiles\"
    $DefaultParameters = '--disable-usage-statistics-question --side-profile-minimal --with-feature:side-profiles --no-default-browser-check'
    $PathSuffix = '\_side_profiles'
    $CopyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob', 'Sessions')
    $Preserve = @('Bookmarks', 'History', 'Bookmarks.bak', 'Web Data', 'Extension State', 'Cookies', 'Cache')
    $ExcludedExtensions = ".pam,.zip,.tar,.gz,.null,.gpg,.woff2,.woff,.bs,.ini,.ttf"

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

    $ProfilePath = if (Test-Path $Profile) { $Profile } else { Join-Path -Path $ProfileFolderPath -ChildPath $Profile }
    $ProfileParam = '--side-profile-name="' + $ProfilePath + '"'

    $ExtensionParam = if ($Extensions) { " --load-extension='" + ($Extensions -join ',') + "'" } else { "" }
    $DownloadParam = " --download.default_directory='" + $DownloadsPath + "'"

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
}

# Process block
Process {
    # Clear cache before launching the profile
    Clear-Cache -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ProfileAlias -ExcludedExtensions $ExcludedExtensions

    Write-Verbose "Invoking OperaLauncher with parameter $ProfileAlias on drive $DriveLetter"

    # Prepare launcher options
    $LauncherOptions = Prepare-LauncherOptions -Profile $ProfileAlias -Extensions $ExtensionsToLoad -DownloadsPath $DownloadsPath -DefaultParameters $DefaultParameters -ProfileFolderPath $ProfileFolderPath

    # Launch the Opera profile
    Invoke-Expression "Invoke-LaunchProcess -FilePath $LauncherPath -ArgumentList $LauncherOptions"
}

# End block
End {
    # Purge profile and manage cache
    & "$PWD\PurgeProfile.ps1" -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ProfileAlias -CopyToCache $CopyToCache -Preserve $Preserve

    # Clear cache after profile purge
    Clear-Cache -DriveLetter $DriveLetter -PathSuffix $PathSuffix -ChildNode $ProfileAlias -ExcludedExtensions $ExcludedExtensions
}
