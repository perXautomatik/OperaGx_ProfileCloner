function Clear-Cache {
    [CmdletBinding()]
    param (
        $params,
        $driveLet,
        $PathSufix,
        [string]$SourceFolder,
        [string]$ChildNode,
        [string]$ProfileFolderPath,
        [string[]]$ExcludedExtensions,
        [string]$SessionStorage,
        [string[]]$ExcludedFileNames,
        [switch]$PromptForName
     )
    begin 		
    {
        # Retrieve cache directories and process each one
        $PreparedParams = @{
            SourceFolder = $null
            ProfileLocation = $null
            toProcess = $null
            clearCasheToProcess = $null 
            ExcludedExtensions = $null
            ExcludedFileNames = $null
            }
        
        $PreparedParams.ExcludedExtensions = ( @($ExcludedExtensions,$params.ExcludedExtensions ) | ?{$null -ne $_}) | select -First 1
        $PreparedParams.ExcludedFileNames = (@($ExcludedFileNames,$params."ExcludedFileNames") | ?{$null -ne $_}) | select -First 1
        $PreparedParams.SourceFolder = (Join-Path -Path $params.DriveLet -ChildPath $params.PathSufix)
        $PreparedParams.ProfileLocation = Join-Path -Path ($PreparedParams.SourceFolder) -ChildPath $params.ChildNode
        $PreparedParams.toProcess = Get-ChildItem -Path ($PreparedParams.ProfileLocation) -Depth 1 -Include "cache"                    
        $PreparedParams.clearCasheToProcess = $PreparedParams.toProcess | % {Get-ChildItem -Path $_.FullName  }	
        
        function HashKeys-ByFunction {
            param (
                $commandName,
                $HashedParams
                )
                # Get the list of valid parameter names for the function
                $validParameters = (Get-Command $commandName).Parameters.Keys
                # Filter out invalid parameters
                $setFilext = $HashedParams.Keys | ? { $_ -notin $validParameters } ;
                $setFilext | % { $HashedParams.Remove($_) }
                
                return $HashedParams						
            }
    
        function Process-WithProgressBar {
            [CmdletBinding()]
            param (
                [parameter(ValueFromPipeline)]
                $_,
                [Parameter(Mandatory = $true)]
                [scriptblock]$ProcessBlock,
                [Parameter(Mandatory = $true)]
                [hashtable]$ProgressParams
            )
    
            begin {
                # Initialize variables that are used in the process block
                $current = 0
                $total = $ProgressParams.TotalCount
                $shell = $Host.UI.RawUI
            }
    
            process {
                # Process the current piped object
                $currentObject = $_
    
                # Increment the current count
                $current++
    
                # Calculate the percentage of completion
                $percent = ($current / $total) * 100
    
                # Update the progress parameters
                $ProgressParams.PercentComplete = $percent
                $ProgressParams.Status = "Processing item $current of $total"
                
                #invoke
                $ProgressParams.CurrentOperation = $ProcessBlock.Invoke($currentObject).ToString()
                $ProgressParams = HashKeys-ByFunction Write-Progress $ProgressParams;						
                # Display the progress bar using splatting
                Write-Progress @ProgressParams
    
                # Update the console title
                $shell.WindowTitle = "Progress $($ProgressParams.PercentComplete)%"
            }
    
            end {
                # Any cleanup code if needed
            }
        }
    

        function Get-SessionId {
            param(
                $childPath
            )
    
            $internalItems = ($childPath | get-childitem -ErrorAction SilentlyContinue );
            $firtFile = (($internalItems | Sort-Object CreationTime | Select-Object -First 1).CreationTime);
            $lastFile = (($internalItems | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime);
            $setFilext = $lastFile -$firtFile
    
            if($setFilext.Days -gt 0)
            {
                $from = get-date -date $firtFile  -Format "yyMMdd_HHmmss"
                $to = get-date -date $lastFile  -Format "yyMMdd_HHmmss"
                $sessionId = "$from to $to"
            }
            else {  
                $sessionId = (Get-Date -Format "yyMMdd_HHmmss");
            }
    
            
            return $sessionId;
        }

        function Move-ToSessionStorage {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)] [string]$OriginalFolderPath,			
                [Parameter(Mandatory = $false)] [string]$ExcludedExtensions,			
                [Parameter(Mandatory = $true)] [string]$NewFolderPath,
                [Parameter(Mandatory = $false)] [string]$ExcludedFileNames
            )
                        
            # Retrieve all files in the original folder path
            $files = Get-ChildItem -Path $OriginalFolderPath -File
                            
            # Filter files to exclude the specified extensions
            $filesToMove = $files | ?{ $_.Extension -notin ($ExcludedExtensions -split ",") }| ?{ $_.Name -notin ($ExcludedFileNames -split ",") }
        
            # Check if there are files to move
            if ($filesToMove) {
                # Ensure the new folder path exists
                $null = New-Item -ItemType Directory -Force -Path $NewFolderPath
                if (Test-Path $NewFolderPath) {
                    # Move the filtered files
                    foreach ($file in $filesToMove) {
                        Move-Item -Path $file.FullName -Destination $NewFolderPath -PassThru
                    }
            
                    # Output the count of moved files
                    Write-Verbose "$($filesToMove.Count) file(s) moved to $NewFolderPath"	
                }
                else {
                    Write-Error "SessionFolder not created!"
                    exit
                }
                
            }
            else {
                Write-Host "No files to move based on the specified extensions."
            }
        }
        

	
    }
    process {
        $PreparedParams.clearCasheToProcess | %{
            $currentFolder = $_
            
            try {
                Get-ChildItem $currentFolder -ErrorAction Stop
            }
            catch {                
                $currentFolder = get-item ($currentFolder.Target)
            }


            try {                                
                $nrChildren = ( Get-ChildItem $currentFolder  -ErrorAction Stop).Length
            }
            catch {
                $nrChildren = 0
            }
            $internalVars = @{
                currentFolder = $currentFolder
                parentName = $currentFolder.Parent.Parent.Name
                newFolder = $null
                theFolderExsistsError = $null
            }
            
            if ($nrChildren -gt 0) {
                try {
                        $saveSuffix = (Get-SessionId -ChildPath $currentFolder)
                    if ($promptForName) {
                     #TODO:   $saveSuffix += PromptForName();
                    }
                    else {
                                               
                    }
                    
                    $internalVars.newFolder = Join-Path -Path $params.SessionStorage -ChildPath (join-path $currentFolder.Parent.Parent.Name $saveSuffix)  -ErrorAction Stop                                            
                    
                    
                    $internalVars.theFolderExsistsError = (Get-ChildItem -Path $internalVars.newFolder -ErrorAction SilentlyContinue).Length -gt 0                            
                    # Check if the new folder already exists
                        if ($internalVars.theFolderExsistsError) {
                            Write-Debug "The folder already exists."
                        } else {
                        
                        # Change file extensions before moving
                        $currentFolder.FullName | & $global:setFilextPath

                        # Define parameters for moving files based on extension
                        $moveParams = @{
                            ExcludedExtension = $PreparedParams.ExcludedExtensions
                            ExcludedFileNames = $PreparedParams.ExcludedFileNames
                            OriginalFolderPath = $currentFolder.FullName
                            NewFolderPath = $internalVars.newFolder
                        }
                        
                        # Move files based on the defined parameters
                        Move-ToSessionStorage @moveParams
                    }	
                
                }
                catch {
                    Write-Error $_    
                }
            }
            else {
                Write-Debug "the folder is empty, skipping"
            }
            
        }
    }

    end {
        # Return to the original location
        Pop-Location	
    }
}
