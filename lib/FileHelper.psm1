#src: https://devblogs.microsoft.com/scripting/use-a-powershell-function-to-see-if-a-command-exists/
function Test-CommandExists {
    Param ($command)
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { Get-Command $command; return $true }
    catch {return $false}
    finally { $ErrorActionPreference=$oldErrorActionPreference }
}
function touch($file) 				            { "" | Out-File $file -Encoding ASCII }
	function split-fileByLineNr                     { param( $pathName = '.\gron.csv',$OutputFilenamePattern = 'output_done_' , $LineLimit = 60)                                                                                                                                                                         ; $input = Get-Content                                                                  ; $line = 0                                                        ; $i = 0                                                       ; $path = 0                                                                       ; $start = 0                                   ; while ($line -le $input.Length) { if ($i -eq $LineLimit -Or $line -eq $input.Length)                                                                                                                                                                                                                                                                 { ; $path++                     ; $pathname = "$OutputFilenamePattern$path.csv"             ; $input[$start..($line - 1)]   | Out -File $pathname -Force   ; $start = $line ;                                  ; $i = 0                       ; Write -Host "$pathname"     ; }                         ; $i++                        ;            ; $line++                     ; }                                                                 ;                                ;}
	
	function split-fileByLineNr { param( $pathName = '.\gron.csv',$OutputFilenamePattern = 'output_done_' , $LineLimit = 60) ;
		$ext = $pathName | split-path -Extension 
		 $inputx = Get-Content ;
		 $line = 0 ;
		 $i = 0 ;
		 $path = 0 ;
		 $start = 0 ;
		 while ($line -le $inputx.Length) {
		      if ($i -eq $LineLimit -Or $line -eq $inputx.Length) {
		    $path++ ;
		    $pathname = "$OutputFilenamePattern$path$ext" ;
		    $inputx[$start..($line - 1)] | Out -File $pathname -Force ;
		    $start = $line ;
 
		    $i = 0 ;
		    Write-Host "$pathname" ;
		    } ;
		 $i++ ;
		 $line++ 
		 }
	}  
	
	function split-fileByMatch {
		 param( $pathName = 'C:\Users\crbk01\Documents\WindowsPowerShell\snipps\Modules\Todo SplitUp.psm1' , $regex = '(?<=function\s)[^\s\(]*') ;
		 $ext = ($pathName | split-path -Extension)
		 $parent = ($pathName | split-path -Parent)
		 $OriginalName = ($pathName | split-path -LeafBase)
		 $inputx = Get-Content $pathName; $line = 0 ; $i = 0 ; $start = @(select-string -path $pathName -pattern $regex ) | select linenumber ; $LineLimit = $start | select -Skip 1 ; $names = @() ; [regex]::matches($inputx,$regex).groups.value | %{$names+= $_ }
		 $occurence = 0 ;
 

		 while ($line -le $inputx.Length) {
		    if ($i -eq ([int]$LineLimit[$occurence].linenumber -1) -Or $line -eq $inputx.Length) 
		    {    
		        $currentName = $names[$occurence];
		        $pathname = Join-Path -path $parent -childPath "$OriginalName-$currentName$ext" ;
		        $u = ([int]$start[$occurence].linenumber -1)
    
		        $inputx[$u..($line - 1)] > $pathname
    
		        $occurence++ ; 
		        Write-Host "$u..($line - 1)$pathname" ;
		    };
		 $i++ ;
		 $line++ 
		 }
	}

if ( $(Test-CommandExists 'trid') )   
{
function SetFileExtension()
	{
		set-location (get-clipboard); 
		$location = get-clipboard # Get the list of files in the current directory
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

	
	function Set-FileExtensionIfNotMatch($fileName) {
	  # Get the current file extension
	  $currentExtension = [System.IO.Path]::GetExtension($fileName)

	  # Get the expected file extension from trid
	  $expectedExtension = Get-FileExtensionFromTrid($fileName)

	  # Check if the current and expected extensions are different
	  if ($currentExtension -ne $expectedExtension) {
	    # Rename the file with the expected extension
	    Rename-Item -Path $fileName -NewName ("$fileName$expectedExtension")
	    # Write a message to the output
	    Write-Output "Renamed file '$fileName' to have extension '$expectedExtension'"
	  }
	}
	
	function Get-FileExtensionFromTrid($fileName) {
	  # Invoke trid with the file name and capture the output
	  $tridOutput = trid $fileName

	  # Check if the output contains any matches
	  if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
	    # Get the highest percentage match and its corresponding extension
	    $highestMatch = ($tridOutput | Select-String "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)" -AllMatches).Matches | Select-Object -First 1
	    $extension = ($highestMatch.Groups[2].Value -split '/')[0]

	    # Return the extension
	    return $extension
	  }
	  else {
	    # Return an empty string if no matches are found
	    return ""
	  }
	}         
}