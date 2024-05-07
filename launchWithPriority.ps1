# Define the arguments and options for the process
$AllArgs = @($param, '--disable-usage-statistics-question --side-profile-minimal --with-feature:side-profiles --no-default-browser-check')
echo $AllArgs
$processOptions = @{
    FilePath = $launcher
    ArgumentList = $AllArgs
}

# Start the process with the -PassThru parameter and assign it to a variable
$Process = Start-Process @processOptions -Wait -PassThru

# Set the priority of the process to above normal
$Process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::AboveNormal

