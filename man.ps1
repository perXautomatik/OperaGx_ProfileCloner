
<#
todo: predefined profile aliases, say "image" with bath image downloader crx
or "organize" with bookmark deduplication to not need to dig up the path and specifying directly
todo: just load all crxs in folder, use alias to filter.
todo: psreadline completion from profile folder
todo: specify cache path ( todays date, and profileName ) 
todo: cache deduplication? ( autodele files occuring always? )
todo: specifying folders to delete on closing, or files to keep

#>

 
#--allowlisted-extension-id ⊗	Adds the given extension ID to all the permission allowlists. ↪
#--apps-gallery-download-url ⊗	The URL that the webstore APIs download extensions from. Note: the URL must contain one '%s' for the extension ID. ↪
#--copy-to-download-dir ⊗	Copy user action data to download directory. ↪



param(    
  [Parameter(Mandatory=$true,
             Position=0,
             ParameterSetName="ParameterSetName",
             ValueFromPipeline=$true,
             ValueFromPipelineByPropertyName=$true,
             HelpMessage="ProfileName")]
  [Alias("childNode")]
  [Alias("profileName")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $profile_ = 'a_jap',  
  $driveLet = 'E:',
  [array]$excludedExtensions = @(".pam", ".zip", ".tar"),   

  $copyToCache = @('IndexedDB\chrome-extension_jdbgjlehkajddoapdgpdjmlpdalfnenf_0.indexeddb.blob','Sessions'),
  $preserve =  @('Bookmarks'
                ,'History'
                ,'Bookmarks.bak'
                ,'Web Data','Extension State'
                ,'Cookies','Cache')
  )
  #--allow-profiles-outside-user-dir
 <# 
  @(
  "$pwd\crx\VisualBookmarks_5_12_2_0.crx",
  "$pwd\crx\Folderwise-Bookmarks-Search-Sessions.crx",
  "$pwd\crx\downloadhelper_8_2_0_20.crx"
  ),
#>


import-module ".\lib\FileHelper.psm1"

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

    function todo-Invoke-OperaLauncher {
    [CmdletBinding(SupportsShouldProcess)]
    param (
      [Parameter(Mandatory, Position = 0)]
      [string]
      $childNode,
      [Parameter(Position = 1)]
      [string]
      $DriveLetter = 'F:',
      [Parameter (ParameterSetName='Encode', Mandatory=$True)]
      [Switch]
      [Bool]$Encode,
      [Parameter (ParameterSetName='Decode', Mandatory=$True)]
      [Switch]
      [Bool]$Decode
    )
  
    # Embed the code for registering the custom predictor module
    try {
      Register-ArgumentCompleter -CommandName $PSCmdlet.MyInvocation.MyCommand.Name -ParameterName childNode -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
  
        # Import the custom predictor module
        Import-Module -Name "$DriveLetter\OperaLauncher\Modules\CustomPredictor.psm1"
  
        # Create unfiltered prediction context object with the current command line
        $context = [PredictionContext]::Create($PSCommandHistory[0])
  
        # Call the GetSuggestion method of the custom predictor class
        $suggestions = $CustomPredictor.GetSuggestion($context, 0, "ListView")
  
        # Convert the suggestions to completion results
        $suggestions | ForEach-Object {
          [System.Management.Automation.CompletionResult]::new($_.SuggestionText, $_.SuggestionText, "ParameterValue", $_.ToolTip)
        }
      }
    }
    catch {
      Write-Error "Failed to register the custom predictor module: $_"
      return
    }
  
    Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $DriveLetter"
  
    if ($PSCmdlet.ShouldProcess("OperaLauncher", "Invoke")) {
      # Check the parameter set name and call the corresponding function
      if ($PSCmdlet.ParameterSetName -eq 'Encode') {
        Encode-OperaLauncher -q $childNode -DriveLetter $DriveLetter
      }
      elseif ($PSCmdlet.ParameterSetName -eq 'Decode') {
        Decode-OperaLauncher -q $childNode -DriveLetter $DriveLetter
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
                ( $_.fullname | SetFileExtensionThroughPiping ) ; 
                moveBasedONextnesion -excludedExtension $exc -originalFolderPath $_.fullname -newFolderPath $newFol
            }                
            
        }    

        Pop-Location;

    }

function EnviromentProperties {
  [CmdletBinding()]
  param (            
      $launcherDirectory = "$pwd\OperaGXPortable\App\OperaGX",
      $launcher = "$launcherDirectory\launcher.exe",
      $pathSufix = '\_side_profiles',
      $scriptLoc = '\OperaLauncher',
      $profileFolder = "\profile\data\$pathSufix",
      $dls = (Join-Path $pwd "downloads")
  )

  return @{
    dls = $dls
    launcher = $launcher
    pathSufix = $pathSufix
    scriptLoc = $scriptLoc
    profileFolder = $profileFolder
  }
}
function Default_LauncherOptions {
  [CmdletBinding()]
  param (            
    $defaultP = 
    '--disable-usage-statistics-question' +
    ' --side-profile-minimal' +
    ' --with-feature:side-profiles' +
    ' --no-default-browser-check'
  )

  return  $defaultP  
}
function prepLauncherOptions {
  [CmdletBinding()]
  param (    
    [alias("a")]$profile_,
    [alias("extensions")][array] $crx,
    $dls
  )
    
  if(test-path $profile_) { $sp = $profile_} else { $sp = (join-path -path $profileFolder -child $profile_) }; $parax = '--side-profile-name=' +'"'+ $sp+'"'

  $extz = get-childitem -path "$pwd\crx"; if(!$crx) { $extensionsToLoad = ($extz | ?{ $_.name -in $crx } ).fullname } else { $extensionsToLoad = ($extz ).fullname }
  if($extensionsToLoad)
  {
    $parax = $parax + " --load-extension=" +'"'+ ($extensionsToLoad -join ',') +'"'
  }

  if($dls){
    $parax = $parax + " --download.default_directory=" +'"'+ $dls +'"'
  }
  
  $AllArgs = @($parax, (Default_LauncherOptions));  Write-Verbos $AllArgs
  
  return $AllArgs
}

function Launch {

  param(
    $processOptions = @{
      FilePath = (EnviromentProperties)
      ArgumentList = (prepLauncherOptions)
    }
  )
  ;  Write-Verbos $processOptions
  
  Start-Process @processOptions -Wait     
}

 
clearCache -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode

Write-Verbose "Invoking OperaLauncher with parameter $childNode on drive $driveLet"
Set-Location $driveLet\;
Launch -a $childNode


& .\OperaLauncher\PurgeProfile.ps1 -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode -CopyToCache $copyToCache -preserve $preserve

clearCache -driveLet $driveLet -pathSufix $pathSufix -childNode $childNode