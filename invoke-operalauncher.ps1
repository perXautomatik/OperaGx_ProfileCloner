function Invoke-OperaLauncher {
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

