# CustomPredictor.psm1

using namespace System.Management.Automation.Subsystem

class CustomPredictor : IPredictor
{
    # Constructor
    CustomPredictor()
    {
        $this.Id = "CustomPredictor"
        $this.Name = "Custom Predictor"
        $this.Description = "A predictor that suggests folder names for the q parameter"
    }

    # Required properties
    [string] $Id
    [string] $Name
    [string] $Description

    # Implement the GetSuggestion method
    [void] GetSuggestion([PredictionContext] $context, [int] $cancellationToken, [PredictionViewStyle] $viewStyle)
    {
        # Get the current command line
        $commandLine = $context.History[0]

        # Check if the command line contains the function name and the parameter name
        if ($commandLine -match "Invoke-OperaLauncher.*-q")
        {
            # Get the drive letter from the command line
            $driveLetter = $commandLine -replace ".*-DriveLetter\s+(\w:).*", '$1'

            # Get the folder path from the drive letter
            $folderPath = "$driveLetter\OperaGXPortable\App\OperaGX\profile\data\_side_profiles"

            # Get the folder names from the folder path
            $folderNames = Get-ChildItem -Path $folderPath -Directory | Select-Object -ExpandProperty Name

            # Create a list of suggestions
            $suggestions = [System.Collections.Generic.List[PredictionResult]]::new()

            # Loop through the folder names
            foreach ($folderName in $folderNames)
            {
                # Create a suggestion text by appending the folder name to the command line
                $suggestionText = "$commandLine $folderName"

                # Create a prediction result object with the suggestion text and the source
                $predictionResult = [PredictionResult]::new($suggestionText, $this.Name)

                # Add the prediction result to the list of suggestions
                $suggestions.Add($predictionResult)
            }

            # Return the list of suggestions
            return $suggestions
        }
    }
}

# Export the predictor class as a variable
$CustomPredictor = [CustomPredictor]::new()
