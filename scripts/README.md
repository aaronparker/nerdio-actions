# Azure Virtual Desktop images

## Install scripts

Image scripts for customising Windows 10/11 Enterprise and Enterprise multi-session images for use with Azure Virtual Desktop via Nerdio Manager scripted actions. These scripts can be used to update an existing gold image or session host - where possible, application update features are disabled.

Scripts use [Evergreen](https://stealthpuppy.com/evergreen/) to determine the latest version of an application. Running each script will install the latest version on a clean image or update an existing application install on a gold image or existing session hosts.

Where supported, application installers will save install logs to `$env:ProgramData\Evergreen\Logs`.

### Core support scripts

* `000_PrepImage.ps1` - Preps the image for installing updates and applications
* `011_SupportFunctions.ps1` - Installs [Evergreen](https://stealthpuppy.com/evergreen/), [VcRedist](https://vcredist.com/) and PSWindowsUpdate PowerShell modules required for installing applications
* `012_WindowsUpdate.ps1` - Installs Windows updates
* `013_RegionLanguage.ps1` - Configures regional/language settings. Use [secure variables](https://nmw.zendesk.com/hc/en-us/articles/4731671517335-Scripted-Actions-Global-Secure-Variables) to pass a system language to this script. Sets `en-AU` by default
* `014_RolesFeatures.ps1` - Enable or disables / removes Windows roles, features and capabilities
* `015_Customise.ps1` - Installs [Windows Customised Defaults](https://stealthpuppy.com/image-customise/). Use [secure variables](https://nmw.zendesk.com/hc/en-us/articles/4731671517335-Scripted-Actions-Global-Secure-Variables) to pass a system language to this script. Sets `en-AU` by default

### Microsoft dependencies

* `100_MicrosoftVcRedists.ps1` - Installs the supported Microsoft Visual C++ Redistributables via [VcRedist](https://vcredist.com/)
* `101_Avd-Agents.ps1` - Installs Azure Virtual Desktop agents
* `102_MicrosoftFSLogixApps.ps1` - Install the Microsoft FSLogix Apps agent
* `103_MicrosoftNET.ps1` - Installs the Microsoft .NET Windows Desktop Runtime
* `104_MicrosoftEdge.ps1` - Installs Microsoft Edge and Microsoft Edge WebView2 Runtime

### Microsoft applications

* `200_MicrosoftOneDrive.ps1` - Installs Microsoft OneDrive per-machine
* `201_MicrosoftTeams.ps1` - Installs Microsoft Teams per-machine (this script will also [update an existing install](https://learn.microsoft.com/en-us/microsoftteams/teams-for-vdi#install-or-update-the-teams-desktop-app-on-vdi) of Teams)
* `202_Microsoft365Apps.ps1` - Installs the latest Microsoft 365 Apps for Enterprise, Current channel, 64-bit with shared computer licensing and updates disabled (includes an embedded configuration.xml)

### Third party applications

* `400_AdobeAcrobatReaderDC.ps1` - Installs the latest Adobe Acrobat Reader MUI 64-bit with automatic updates disabled
* `401_ZoomMeetings.ps1` - Installs the latest Zoom Meetings VDI client
* `402_FoxitPDReader.ps1` - Installs the latest Foxit PDF Reader with automatic updates disabled
* `403_GoogleChrome.ps1` - Installs the latest Google Chrome 64-bit with automatic updates disabled
* `404_NotepadPlusPlus.ps1` - Installs the latest Notepad++ 64-bit with automatic updates disabled
* `405_pdfforgePDFCreator.ps1` - Installs the latest PDFForge PDFCreator (note: this is not the [Terminal Server](https://www.pdfforge.org/pdfcreator/editions/pdfcreator-terminal-server) edition)
* `406_VLCMediaPlayer.ps1` - Installs the latest VLC media player 64-bit
* `407_7Zip.ps1` - Installs the latest 7-Zip 64-bit
* `408_RemoteDesktopAnalyzer.ps1` - Downloads the Remote Display Analyzer to `C:\Program Files\RemoteDisplayAnalyzer`
* `409_CiscoWebEx.ps1` - Installs the specified version of Cisco WebEx VDI client with automatic updates disabled. URL to the installer is hard coded in this script
* `410_ImageGlass.ps1` - Installs the latest version of ImageGlass. Use a replacement for the Photos app
* `411_draw.io.ps1` - Installs the latest version of draw.io / diagrams.net
* `412_MozillaFirefox.ps1` - Installs the latest of Mozilla Firefox 64-bit en-US with updates disabled
* `413_Paint.NET` - Installs the latest of paint.net 64-bit with updates disabled

### Clean up scripts

* `99_CleanupImage.ps1` - Cleans up the image post install and update (e.g. deletes C:\Apps)

Once run on the target VM, the VM or image should have the following applications installed:

![Applications installed into the VM/image](apps.png)

## Uninstall scripts

Scripts here will uninstall target applications. Run on gold images or target session hosts when users are not signed in, as applications will be forcibly uninstalled.

Where supported, uninstall commands will save uninstall logs to `$env:ProgramData\Evergreen\Logs`.
