# Azure Virtual Desktop images

Scripts for customising Windows 10/11 Enterprise and Enterprise multi-session images for use with Azure Virtual Desktop via Nerdio Manager scripted actions. These scripts can be used to update an existing gold image or session host.

* `00_Rds-PrepImage.ps1` - Preps the image for installing updates and applications
* `01_SupportFunctions.ps1` - Installs [Evergreen](https://stealthpuppy.com/evergreen), [VcRedist](https://vcredist.com) and PSWindowsUpdate PowerShell modules required for installing applications
* `02_WindowsUpdate.ps1` - Installs Windows updates
* `03_RegionLanguage.ps1` - Configures regional/language settings. Use [secure variables](https://nmw.zendesk.com/hc/en-us/articles/4731671517335-Scripted-Actions-Global-Secure-Variables) to pass a system language to this script. Sets `en-AU` by default
* `04_RolesFeatures.ps1` - Enable or disables / removes Windows roles, features and capabilities
* `05_Customise.ps1` - Installs [Windows Customised Defaults](https://stealthpuppy.com/image-customise). Use [secure variables](https://nmw.zendesk.com/hc/en-us/articles/4731671517335-Scripted-Actions-Global-Secure-Variables) to pass a system language to this script. Sets `en-AU` by default
* `06_MicrosoftVcRedists.ps1` - Installs the supported Microsoft Visual C++ Redistributables
* `07_Avd-Agents.ps1` - Installs the Azure Virtual Desktop agents
* `08_MicrosoftNET.ps1` - Installs the Microsoft .NET Windows Desktop Runtime
* `09_MicrosoftFSLogixApps.ps1` - Install the Microsoft FSLogix Apps agent
* `10_MicrosoftEdge.ps1` - Installs Microsoft Edge and Microsoft Edge WebView2 Runtime
* `11_MicrosoftOneDrive.ps1` - Installs Microsoft OneDrive per-machine
* `12_MicrosoftTeams.ps1` - Installs Microsoft Teams per-machine (this script will update Teams)
* `20_Microsoft365Apps.ps1` - Installs the latest Microsoft 365 Apps for Enterprise, Current channel, 64-bit with shared computer licensing and updates disabled (includes an embedded configuration.xml)
* `39_AdobeAcrobatReaderDC.ps1` - Installs the latest Adobe Acrobat Reader MUI 64-bit with automatic updates disabled
* `40_ZoomMeetings.ps1` - Installs the latest Zoom Meetings VDI client
* `41_FoxitPDReader.ps1` - Installs the latest Foxit PDF Reader with automatic updates disabled
* `42_GoogleChrome.ps1` - Installs the latest Google Chrome 64-bit with automatic updates disabled
* `43_NotepadPlusPlus.ps1` - Installs the latest Notepad++ 64-bit with automatic updates disabled
* `44_pdfforgePDFCreator.ps1` - Installs the latest PDFForge PDFCreator
* `45_VLCMediaPlayer.ps1` - Installs the latest VLC media player 64-bit
* `46_7Zip.ps1` - Installs the latest 7-Zip 64-bit
* `47_RemoteDesktopAnalyzer.ps1` - Downloads the Remote Display Analyzer to `C:\Program Files\RemoteDisplayAnalyzer`
* `99_CleanupImage.ps1` - Cleans up the image post install and update (e.g. deletes C:\Apps)

Once run on the target VM, the VM or image should have the following applications installed:

![Applications installed into the VM/image](apps.png)
