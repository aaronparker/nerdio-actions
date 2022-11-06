# Azure Virtual Desktop images

Scripts for customising Windows 10/11 Enterprise and Enterprise multi-session images for use with Azure Virtual Desktop.

* `00_Rds-PrepImage.ps1` - Preps the image for installing updates and applications
* `01_SupportFunctions.ps1` - Installs [Evergreen](https://stealthpuppy.com/evergreen) and [VcRedist](https://vcredist.com) PowerShell functions required for installing applications
* `02_WindowsUpdate.ps1` - Installs Windows updates
* `03_RegionLanguage.ps1` - Configures regional/language settings
* `04_Rds-Roles.ps1` - Enable or disables / removes Windows roles, features and capabilities
* `05_Customise.ps1` - Installs [Windows Customised Defaults](https://stealthpuppy.com/image-customise)
* `06_MicrosoftVcRedists.ps1` - Installs the supported Microsoft Visual C++ Redistributables
* `07_MicrosoftNET.ps1` - Installs the Microsoft .NET Windows Desktop Runtime
* `08_MicrosoftFSLogixApps.ps1` - Install the Microsoft FSLogix Apps agent
* `09_MicrosoftEdge.ps1` - Installs Microsoft Edge
* `10_Microsoft365Apps.ps1` - Installs the Microsoft 365 Apps (includes an embedded configuration.xml)
* `11_MicrosoftTeams.ps1` - Installs Microsoft Teams per-machine
* `12_MicrosoftOneDrive.ps1` - Installs Microsoft OneDrive per-machine
* `14_Wvd-Agents.ps1` - Installs the Azure Virtual Desktop agents
* `39_AdobeAcrobatReaderDC.ps1` - Installs Adobe Acrobat Reader DC MUI 64-bit
* `98_FinaliseImage.ps1` - Finalises the image post install and update
* `99_Sysprep-Image.ps1` - Syspreps the image, only if the Citrix VDA is not installed
