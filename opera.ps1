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
 <# 
  @(
  "$pwd\crx\VisualBookmarks_5_12_2_0.crx",
  "$pwd\crx\Folderwise-Bookmarks-Search-Sessions.crx",
  "$pwd\crx\downloadhelper_8_2_0_20.crx"
  ),
#>


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

function presentFolders{

    param(
        [alias('hard')] $hardpath = $false,
        $profilex = $a
    )

    if($hardpath)
    {      
      $folders = Get-ChildItem -Path $profileFolder -Directory ; 
      $presentFolders =  $folders | Sort-Object -Property name, LastWriteTime -Descending 

      $SelectedFolder = ( $presentFolders | ? { $_.name -eq $profilex} | select name -First 1).Name

      if(!($SelectedFolder))
      {
          $toRename = (selectItemFromListBox -list $presentFolders)
                      
          $toRename | Rename-Item -NewName $profilex

          $SelectedFolder = ( ($folders)   |
                    ? { $_.name -eq $profilex} |
                     select name -First 1).Name
      }
      return $SelectedFolder
    }
  else
  {
      return $profilex
  }
      
}

function rnAfter{
  
      if($RenameAfter){
      echo "after waiting"
      #'353238305F393330303834303437' 
      $prof = (RenameAsCopyMoveTask -hard $false )
      presentFolders          
      [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

      $title = 'Do you want to rename '+$profilex
      $msg   = 'NewName:'

      $text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
      if($text)
      {
          ($profileFolder | Join-Path -ChildPath $profilex) | Rename-Item -NewName $text
      }
      else
      {
      echo "empty"
      }
  }
}

   

Launch_opera_profile #; rnAfter

