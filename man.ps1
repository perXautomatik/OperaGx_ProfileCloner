
param(
  $a = 'a_jap',
  $profileFolder = "$pwd\OperaGXPortable\App\OperaGX\profile\data\_side_profiles\",
  $rename = $true,
  $operaType = "portable",
  $profileInProfileFolder = $true,
  $RenameAfter = !($a -match 'a_') -or $rename,
  $cloneIfempty = $true,
  $dls = (Join-Path $pwd "downloads"),
  $defaultP =
		'--disable-usage-statistics-question' +
		' --side-profile-minimal' +
		' --with-feature:side-profiles' +
		' --no-default-browser-check' +
		" --download.default_directory=$dls"
		,
		$extensionsToLoad = (get-childitem -path "$pwd\crx").fullname
  , $launcher = ".\OperaGXPortable\App\OperaGX\launcher.exe"
  )

import-module ".\lib\FileHelper.psm1"

<#
todo: predefined profile aliases, say "image" with bath image downloader crx
or "organize" with bookmark deduplication to not need to dig up the path and specifying directly
todo: just load all crxs in folder, use alias to filter.
todo: psreadline completion from profile folder
todo: specify cache path ( todays date, and profileName )
todo: cache deduplication? ( autodele files occuring always? )
todo: specifying folders to delete on closing, or files to keep

#>


#--allowlisted-extension-id ?	Adds the given extension ID to all the permission allowlists. ?
#--apps-gallery-download-url ?	The URL that the webstore APIs download extensions from. Note: the URL must contain one '%s' for the extension ID. ?
#--copy-to-download-dir ?	Copy user action data to download directory. ?


 <#
  @(
  "$pwd\crx\VisualBookmarks_5_12_2_0.crx",
  "$pwd\crx\Folderwise-Bookmarks-Search-Sessions.crx",
  "$pwd\crx\downloadhelper_8_2_0_20.crx"
  ),
#>


function SetFileExtensionThroughPiping()
	{
	[CmdletBinding()]
	param (
	    [Parameter(ValueFromPipeline = $true)]
	    [ValidateNotNullOrEmpty()]
	    [ValidateScript({
		if($_.psobject.Methods.Match.('ToString'))
		{
		    $true
		}
		else
		{
		    throw 'Can''t convert pipeline object to string!'
		}
	    })]
	    $parmPath
	)


		set-location ($parmPath);
		$location = $parmPath # Get the list of files in the current directory
		$files = Get-ChildItem -File

		# Get the total number of files
		$total = $files.Count

		# Initialize unfiltered counter for the current file
		$current = 0

	$shell = $Host.UI.RawUI


	$shell.WindowTitle= "Progress 0% @ $($location)"


		$files | % {
		$file = $_
		  $current++

		  # Calculate the percentage of completion
		  $percent = ($current / $total) * 100

		  # Change the console title
		  $shell.WindowTitle  = "Progress $($percent)% @ $($location)"

		  # Write unfiltered progress message with unfiltered progress bar
		  Write-Progress -Activity "Setting file extensions in $location" -Status "Processing file $current of $total" -PercentComplete $percent -CurrentOperation "Checking file '$($file.Name)'"

		  # Set the file extension if it does not match the one from trid
		  Set-FileExtensionIfNotMatch($file.Name)
		}
	}


function Launch_opera_profile {

    if($a)
    {
    $profile = $a
    }
    else
    {
	$profile = (join-path -path $profileFolder -child $a)
    }

    $param = '--side-profile-name=' +'"'+ $profile+'"' #--allow-profiles-outside-user-dir

    if($extensionsToLoad)
    {
	$param = $param + " --load-extension=" +'"'+ ($extensionsToLoad -join ',') +'"'
    }

    $AllArgs = @($param, $defaultP); echo $AllArgs

    $processOptions = @{
	FilePath = $launcher
	ArgumentList = $AllArgs
    }; echo $processOptions

    Start-Process @processOptions -Wait

    return (($profileFolder+$a+"\Cache\Cache_Data") -replace '\\', '\')
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
		( $_.fullname | SetFileExtensionThroughPiping ) ;
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

    Set-Location $driveLet\; Launch_opera_profile -a $childNode
$copyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob','Sessions')
$preserve =  @('Bookmarks'
,'History'
,'Bookmarks.bak'
,'Web Data','Extension State'
,'Cookies','Cache')

    & .\OperaLauncher\PurgeProfile.ps1 -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode -CopyToCache $copyToCache -preserve $preserve

    clearCache -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode