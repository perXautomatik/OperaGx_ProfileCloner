	#function Set-FileExtensionThroughPiping {
		[CmdletBinding()]
		param (
			[Parameter(ValueFromPipeline = $true,Mandatory = $true)]
			[ValidateNotNullOrEmpty()]
			[ValidateScript({
				if($_.length -gt 0) { $true }
				else { throw 'empty string or zero length array provided' }
			})]
			$InputObject
		)

		begin {

			# Define the progress parameters
			$ProgressParams = @{
				TotalCount = 0
				Activity = "Setting file extensions"
				Status = ""
				PercentComplete = 0
				CurrentOperation = ""
			}
      # Helper function to set file extension if it does not match the expected one
    function Set-FileExtensionIfNotMatch {
	[CmdletBinding()]
	Param (
	    [Parameter(Mandatory)]
	    [string]$FileName
	)
		$currentExtension = [System.IO.Path]::GetExtension($FileName)
		$expectedExtension = Get-FileExtensionFromTrid -FileName $FileName

		if ($currentExtension -ne $expectedExtension) {
			Rename-Item -Path $FileName -NewName ("$FileName$expectedExtension")
			Write-Output "Renamed file '$FileName' to have extension '$expectedExtension'"
		}
    }

    # Helper function to get file extension from 'trid' command output
    function Get-FileExtensionFromTrid {
	[CmdletBinding()]
	Param (
	    [Parameter(Mandatory)]
	    [string]$FileName
	)
		$tridOutput = trid $FileName

		if ($tridOutput -match "(\d+\.?\d*)%\s+\((\.\S+)\)\s+(.*)") {
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
	function filter-HashTableForSplatting {
		param (
			$commandName,
			$HashedParams
		)
			# Get the list of valid parameter names for the function
			$validParameters = (Get-Command $commandName).Parameters.Keys
			# Filter out invalid parameters
			$q = $HashedParams.Keys | ? { $_ -notin $validParameters } ;
			$q | % { $HashedParams.Remove($_) }

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
			if($total -eq 0) { $total = 1}			
			# Calculate the percentage of completion
			$percent = ($current / $total) * 100

			# Update the progress parameters
			$ProgressParams.PercentComplete = $percent
			$ProgressParams.Status = "Processing item $current of $total"

			#invoke
			$ProgressParams.CurrentOperation = $ProcessBlock.Invoke($currentObject).ToString()
			$ProgressParams = filter-HashTableForSplatting Write-Progress $ProgressParams;
			# Display the progress bar using splatting
			Write-Progress @ProgressParams

			# Update the console title
			$shell.WindowTitle = "Progress $($ProgressParams.PercentComplete)%"
		}

		end {
			# Any cleanup code if needed
		}
	}
		}
		process {

			foreach ($item in $InputObject) {
				# Determine if the input is a file or directory
				if (Test-Path $item -PathType Leaf) {
					# It's a file, add to processing list
					$files += Get-Item $item
				} elseif (Test-Path $item -PathType Container) {
					# It's a directory, add all files within to processing list
					$files += Get-ChildItem $item -File
				}
			}
			
			if ($files) {
				$ProgressParams.TotalCount = $files.Count;
				# Process each file with the progress bar
				$files | Process-WithProgressBar -ProcessBlock {
					param($file)
					# Your processing code here
					Set-FileExtensionIfNotMatch $file.FullName
				} -ProgressParams $ProgressParams
			}
			

		}
		end {
			# Any cleanup code if needed
		}
