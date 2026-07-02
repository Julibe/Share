
# Custom Chocolatey codes
This is a list of the programs I use to install from Chocolatey.

## CMD
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1('))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
## PowerShell
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


<details>
  <summary>Install</summary>
 ## Choco

    choco install choco-protocol-support chocolatey chocolatey-core.extension chocolatey-dotnetfx.extension chocolatey-misc-helpers.extension chocolatey-windowsupdate.extension chocolateygui wingetui -y

 ## Browsers

    choco install firefox googlechrome microsoft-edge opera brave vivaldi safari authy-desktop tor-browser opera-gx -y

 ## Transfer

    choco install qbittorrent  -y

 ## Tools

    choco install 7zip.install phraseexpress powertoys bulkrenameutility sagethumbs  qttabbar phraseexpress.install Ghostscript.app autohotkey.portable file-converter xnviewmp.install irfanview foxitreader caesium.install -y

 ## Security

    choco install ccleaner bulk-crap-uninstaller ccenhancer ccenhancer.install afedteated driverbooster iobit-uninstaller attributechanger Recuva  -y

 ## Runtime

    choco install openal silverlight xna KB2533623 KB2919355 KB2919442 KB2999226 KB3033929 KB3035131 directx vcredist140 vcredist2008 vcredist2010 vcredist2013 vcredist2015 vcredist2017 dotnet dotnetfx chocolatey-dotnetfx.extension dotnet-runtime dotnetcore-desktopruntime dotnetcore3-desktop-runtime jre8 javaruntime silverlight Sudo  -y

 ## Media

    choco install handbrake vlc stremio plexmediaserver kodi metax mp3tag k-litecodecpackfull geforce-experience spotify handbrake musicbee  -y

 ## Editor

    choco install kdenlive obs-studio.install audacity shotcut.install krita gimp  -y

 ## Coding

    choco install filezilla git.install heidisql notepadplusplus.install github-desktop mysql.workbench nodejs.install vscode-insiders.install python  -y

 ## Gaming

    choco install steam-client origin gamesavemanager epicgameslauncher goggalaxy ubisoft-connect bethesdanet launchbox directx vortex  -y

 ## Chat

    choco install whatsapp telegram.install zoom skype  -y

 ## Other

    choco install blender adobe-creative-cloud unity fontbase  -y

</details>


