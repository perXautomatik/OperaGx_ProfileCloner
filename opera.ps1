<#
todo: predefined profile aliases, say "image" with bath image downloader crx
or "organize" with bookmark deduplication to not need to dig up the path and specifying directly
todo: just load all crxs in folder, use alias to filter.
todo: psreadline completion from profile folder
todo: specify cache path ( todays date, and profileName ) 
todo: cache deduplication? ( autodele files occuring always? )
 
#>

param(
  $a = 'a_jap',
  $profileFolder = "$pwd\OperaGXPortable\App\OperaGX\profile\data\_side_profiles\",
  $rename = $true,
  $operaType = "portable",
  $profileInProfileFolder = $true,
  $RenameAfter = !($a -match 'a_') -or $rename,
  $cloneIfempty = $true,
  $defaultP = 
                '--disable-usage-statistics-question ' +
                '--side-profile-minimal ' +
                '--with-feature:side-profiles ' +
                '--no-default-browser-check'
                ,   
  $extensionsToLoad = @(
  "$pwd\crx\VisualBookmarks_5_12_2_0.crx",
  "$pwd\crx\Folderwise-Bookmarks-Search-Sessions.crx",
  "$pwd\crx\downloadhelper_8_2_0_20.crx"
  ),

  $launcher = ".\OperaGXPortable\App\OperaGX\launcher.exe"
  )
function Launch_opera_profile ($profile) {
    
    if($profile)
    {
    #--allow-profiles-outside-user-dir
        $param = '--side-profile-name=' +'"'+ $profile+'"'
    }
    else
    {
       $profile = $profileFolder+"\"+ $a;
       $param = '--side-profile-name=' +'"'+ $profile+'"'
    }

    if($extensionsToLoad)
    {
        $param = $param + " --load-extension=" +'"'+ ($extensionsToLoad -join ',') +'"'
    }

    $AllArgs = @($param, $defaultP)

    echo $AllArgs

    $processOptions = @{
        FilePath = $launcher
        ArgumentList = $AllArgs
    }
echo $processOptions
    Start-Process @processOptions -Wait 

    ($profileFolder+$a+"\Cache\Cache_Data") | Set-Clipboard 
}

function RenameAsCopyMoveTask{

param($hardpath = $false)

    $profilex = $a
  if($hardpath)
  {
    
    $folders = Get-ChildItem -Path $profileFolder -Directory
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

function SelectItemFromListBox($list){

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Computer'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select a computer:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

$list | %{
[void] $listBox.Items.Add($_)
}

$form.Controls.Add($listBox)
$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
    $x
}
}

function rnAfter{if($RenameAfter){
    echo "after waiting"

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

 
#--allowlisted-extension-id ⊗	Adds the given extension ID to all the permission allowlists. ↪
#--apps-gallery-download-url ⊗	The URL that the webstore APIs download extensions from. Note: the URL must contain one '%s' for the extension ID. ↪
#--copy-to-download-dir ⊗	Copy user action data to download directory. ↪


#'353238305F393330303834303437' 
$prof = (RenameAsCopyMoveTask -hard $false )
Launch_opera_profile -profile $prof ; rnAfter

$presentFolders             
