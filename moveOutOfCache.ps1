import-module ".\lib\FileHelper.psm1"

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
        ( set-clipboard $_.fullname | & SetFileExtension ) ; 
    
        $originalFolderPath = $_.fullname ; 
        
        $newFolderPath = Join-Path ($sessionStorage) $dateTime ; 
        
        New-Item -ItemType Directory -Force -Path $newFolderPath ;
        
        Get-ChildItem -Path $originalFolderPath -File | 
            ? { $_.Extension } | 
                ? { $_.Extension -notin $excludedExtensions } |
                % { 
                        Move-Item -Path $_.FullName -Destination $newFolderPath 
                    } } }
cd E:\OperaLauncher
MoveOutFromCache                    