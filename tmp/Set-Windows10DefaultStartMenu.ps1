#description: Sets a default Windows 10 Start menu and taskbar layout from a URL passed from  Nerdio secure variables
#execution mode: Combined
#tags: Image, Start menu, Taskbar

#region Use Secure variables in Nerdio Manager to pass variables
# A default Start menu and taskbar layout is included here for local testing
if ($null -eq $SecureVars.StartLayout) {
	[System.String] $StartLayout = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" 
  xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" 
  xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" Version="1" 
  xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:Group Name="">
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationID="com.squirrel.Teams.Teams" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="2" DesktopApplicationID="Microsoft.SkyDrive.Desktop" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationID="MSEdge" />
          <start:DesktopApplicationTile Size="1x1" Column="4" Row="2" DesktopApplicationID="Microsoft.Office.EXCEL.EXE.15" />
          <start:DesktopApplicationTile Size="1x1" Column="4" Row="3" DesktopApplicationID="Microsoft.Office.POWERPNT.EXE.15" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationID="Microsoft.Office.WINWORD.EXE.15" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationID="Microsoft.Office.OUTLOOK.EXE.15" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" />
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
}
else {
	# Host the Start menu and taskbar layout on Azure blob storage
	[System.String] $StartLayoutUrl = $SecureVars.StartLayout
}
#endregion

#region Script logic
[System.String] $Path = "$Env:SystemDrive\Apps\StartLayout"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\Shell" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

if ([System.String]::IsNullOrEmpty($StartLayoutUrl)) {
	$params = @{
		Path        = "$Path\LayoutModification.xml"
		Value       = $StartLayout
		Encoding    = "Utf8"
		NoNewLine   = $true
		Confirm      = $false
		Force       = $true
		ErrorAction = "Stop"
	}
	Set-Content @params
}
else {
	$params = @{
		URI             = $StartLayoutUrl
		OutFile         = "$Path\LayoutModification.xml"
		UseBasicParsing = $true
		ErrorAction     = "Stop"
	}
	Invoke-WebRequest @params
}

Import-StartLayout -LayoutPath "$Path\LayoutModification.xml" -MountPath "$Env:SystemDrive\"
#endregion
