
# Custom Chocolatey codes
This is a list of the programs I use to install from Chocolatey.
## CMD

    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
## PowerShell

    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"



## Iinstall

### Choco

    choco install choco-protocol-support chocolatey chocolatey-core.extension chocolatey-dotnetfx.extension chocolatey-misc-helpers.extension chocolatey-windowsupdate.extension chocolateygui -y

### Browsers

    choco install firefox googlechrome microsoft-edge opera brave vivaldi safari -y

### Tools

    choco install 7zip.install powertoys bulkrenameutility sagethumbs teracopy qttabbar phraseexpress.install Ghostscript.app autohotkey.portable file-converter xnviewmp.install irfanview gimp foxitreader -y

### Security

    choco install ccleaner ccenhancer ccenhancer.install afedteated driverbooster iobit-uninstaller Recuva -y

### Runtime

    choco install KB2533623 KB2919355 KB2919442 KB2999226 KB3033929 KB3035131 directx vcredist140 vcredist2008 vcredist2010 vcredist2013 vcredist2015 vcredist2017 dotnet dotnetfx chocolatey-dotnetfx.extension dotnet-runtime dotnetcore-desktopruntime dotnetcore3-desktop-runtime jre8 javaruntime silverlight Sudo -y

### Media

    choco install vlc stremio plexmediaserver kodi metax mp3tag k-litecodecpackfull obs-studio.install geforce-experience spotify handbrake audacity musicbee -y

### Coding

    choco install filezilla git.install heidisql notepadplusplus.install github-desktop mysql.workbench nodejs.install vscode-insiders.install python -y

### Gaming

    choco install steam-client origin gamesavemanager epicgameslauncher goggalaxy ubisoft-connect bethesdanet directx -y

### Chat

    choco install whatsapp telegram.install zoom skype -y

### Other

    choco install blender fontbase -y
