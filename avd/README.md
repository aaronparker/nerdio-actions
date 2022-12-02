# Azure Virtual Desktop images

Scripts for customising Windows 10/11 Enterprise and Enterprise multi-session images for use with Azure Virtual Desktop.

* `00_Rds-PrepImage.ps1` - Preps the image for installing updates and applications
* `01_SupportFunctions.ps1` - Installs [Evergreen](https://stealthpuppy.com/evergreen), [VcRedist](https://vcredist.com) and PSWindowsUpdate PowerShell modules required for installing applications
* `02_WindowsUpdate.ps1` - Installs Windows updates
* `03_RegionLanguage.ps1` - Configures regional/language settings. Use [secure variables](https://nmw.zendesk.com/hc/en-us/articles/4731671517335-Scripted-Actions-Global-Secure-Variables) to pass a system language to this script
* `04_RolesFeatures.ps1` - Enable or disables / removes Windows roles, features and capabilities
* `05_Customise.ps1` - Installs [Windows Customised Defaults](https://stealthpuppy.com/image-customise). Use [secure variables](https://nmw.zendesk.com/hc/en-us/articles/4731671517335-Scripted-Actions-Global-Secure-Variables) to pass a system language to this script
* `06_MicrosoftVcRedists.ps1` - Installs the supported Microsoft Visual C++ Redistributables
* `07_Avd-Agents.ps1` - Installs the Azure Virtual Desktop agents
* `08_MicrosoftNET.ps1` - Installs the Microsoft .NET Windows Desktop Runtime
* `09_MicrosoftFSLogixApps.ps1` - Install the Microsoft FSLogix Apps agent
* `10_MicrosoftEdge.ps1` - Installs Microsoft Edge - not required for Windows 10 2004+
* `12_Microsoft365Apps.ps1` - Installs the Microsoft 365 Apps (includes an embedded configuration.xml)
* `13_MicrosoftOneDrive.ps1` - Installs Microsoft OneDrive per-machine
* `14_MicrosoftTeams.ps1` - Installs Microsoft Teams per-machine
* `39_AdobeAcrobatReaderDC.ps1` - Installs Adobe Acrobat Reader DC MUI 64-bit
* `99_FinaliseImage.ps1` - Finalises the image post install and update

Once run on the target VM, the VM or image should have the following applications installed:

![Applications installed into the VM/image](apps.png)
