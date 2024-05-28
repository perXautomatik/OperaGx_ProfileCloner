
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
	    Set-FileExtensionIfNotMatch $file.Name
	}
    }
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
	    $sourceFold = (join-path $driveLet $pathSufix),
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
		( $_.fullname | Set-FileExtensionThroughPiping ) ;
		moveBasedONextnesion -excludedExtension $exc -originalFolderPath $_.fullname -newFolderPath $newFol
	    }

	}

	Pop-Location;

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