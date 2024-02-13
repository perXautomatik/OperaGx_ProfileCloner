function Launch_opera_profile ($profile) {
$param = '--side-profile-name=' +'"'+ $profile+'"'
$AllArgs = @($param, ' --with-feature:side-profiles --no-default-browser-check')

echo $AllArgs


start-process   "C:\Program Files\Opera GX\launcher.exe" - $AllArgs -Wait 
}