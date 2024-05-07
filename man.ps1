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

		# Initialize a counter for the current file
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

		  # Write a progress message with a progress bar
		  Write-Progress -Activity "Setting file extensions in $location" -Status "Processing file $current of $total" -PercentComplete $percent -CurrentOperation "Checking file '$($file.Name)'"

		  # Set the file extension if it does not match the one from trid
		  Set-FileExtensionIfNotMatch($file.Name)
		}
	}

function MoveOutFromCache { 
    param (
        $profileName = "a_vin", 
        $driveLetter = "E:", 
        $sessionStorage = "$driveLetter\sessionStorage\$profileName",
        $profileLocation = "$driveLetter\_side_profiles\$profileName\",
        $cachfoldername = "cache",
        $innerCacheFolder = "cache_data"
        ) 
    
        $dateTime = Get-Date -Format "yyyyMMdd_HHmmss";
        $excludedExtensions = @(".pam", ".zip", ".tar", ".gz", ".null", ".gpg", ".woff2", ".woff", ".bs", ".ini" );   
        
        cd $profileLocation ; 
        $a = @(); 
        $q = (get-childitem  -dept 1 -include $cachfoldername) ; 
        
        $a = @($q | get-childitem -filter $innerCacheFolder | select fullname) ; 
        
        $a | % { 
            ( $_.fullname | SetFileExtensionThroughPiping ) ; 
        
            $originalFolderPath = $_.fullname ; 
                             
            $rnd = Get-ChildItem -Path $originalFolderPath -File;
            $withExtensions = $rnd | ? { $_.Extension };
            $excludingExt = $withExtensions | ? { $_.Extension -notin $excludedExtensions };
            
            if ($excludingExt.Length -gt 0){
                $from = ($excludingExt | Sort-Object CreationTime | Select-Object -First 1).CreationTime
                $to = ($excludingExt | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime
                
                $newFolderPath = Join-Path ($sessionStorage) $dateTime ;             
                New-Item -ItemType Directory -Force -Path $newFolderPath ;

                $excludingExt | % {  Move-Item -Path $_.FullName -Destination $newFolderPath  } } 
            }
            else {
                Write-Host "no cache"
            }

    }

    function Invoke-OperaLauncher {
        [CmdletBinding(SupportsShouldProcess)]
        param (
          [Parameter(Mandatory, Position = 0)]
          [string]
          $q,
          [Parameter(Position = 1)]
          [string]
          $DriveLetter = 'F:',
          [array]
          $excludedExtensions = @(".pam", ".zip", ".tar")
        )
      
        Write-Verbose "Invoking OperaLauncher with parameter $q on drive $DriveLetter"
      
        if ($PSCmdlet.ShouldProcess("OperaLauncher", "Invoke")) {
          $originalFolderPath = Invoke-Expression "Set-Location $DriveLetter\; .\OperaLauncher\opera.ps1 -a $q"
          cd "$driveLetter\_side_profiles\$q\" ; $a = @(get-childitem  -dept 1 -include cache | get-childitem | select fullname) ; $a | %{ ( set-clipboard $_.fullname | & SetFileExtension ) ; $originalFolderPath = $_.fullname ; $excludedExtensions = ".pam", ".zip", ".tar" ; $dateTime = Get-Date -Format "yyyyMMdd_HHmmss"; $newFolderPath = Join-Path (Split-Path $originalFolderPath) $dateTime ; New-Item -ItemType Directory -Force -Path $newFolderPath ; Get-ChildItem -Path $originalFolderPath -File | ? { $_.Extension } | ? { $_.Extension -notin $excludedExtensions } | %{ Move-Item -Path $_.FullName -Destination $newFolderPath } }
        }
      }


function todo-Invoke-OperaLauncher {
    [CmdletBinding(SupportsShouldProcess)]
    param (
      [Parameter(Mandatory, Position = 0)]
      [string]
      $q,
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
      Register-ArgumentCompleter -CommandName $PSCmdlet.MyInvocation.MyCommand.Name -ParameterName q -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
  
        # Import the custom predictor module
        Import-Module -Name "$DriveLetter\OperaLauncher\Modules\CustomPredictor.psm1"
  
        # Create a prediction context object with the current command line
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
  
    Write-Verbose "Invoking OperaLauncher with parameter $q on drive $DriveLetter"
  
    if ($PSCmdlet.ShouldProcess("OperaLauncher", "Invoke")) {
      # Check the parameter set name and call the corresponding function
      if ($PSCmdlet.ParameterSetName -eq 'Encode') {
        Encode-OperaLauncher -q $q -DriveLetter $DriveLetter
      }
      elseif ($PSCmdlet.ParameterSetName -eq 'Decode') {
        Decode-OperaLauncher -q $q -DriveLetter $DriveLetter
      }
    }
  }


  
$q = "a_vin" ;
$uu = 'E:';
$yy = '\_side_profiles'
$scriptLoc = '\OperaLauncher'

cd (join-path $uu $scriptLoc);

Get-ChildItem -Path (join-path $uu $yy) -Directory| 
    ?{ $_.name -eq $q } | 
        % { MoveOutFromCache -profileName $_.Name } ;

Invoke-OperaLauncher -DriveLetter $uu -q $q
