#description: Installs Windows language support
#execution mode: Combined
#tags: Language
<#
    .SYNOPSIS
        Set language/regional settings.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Locale = "en-AU"
)

#region Functions
function Set-RegionSetting {
    [CmdletBinding(SupportsShouldProcess = $False)]
    param (
        $Path, $Locale
    )

    if (!(Test-Path $Path)) { New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" }

    # Select the locale
    switch ($Locale) {
        "en-US" {
            # United States
            $GeoId = 244
            $Timezone = "Pacific Standard Time"
            $LanguageId = "0409:00000409"
            $Language = "en-US"
        }
        "en-GB" {
            # Great Britain
            $GeoId = 242
            $Timezone = "GMT Standard Time"
            $LanguageId = "0809:00000809"
            $Language = "en-GB"
        }
        "en-AU" {
            # Australia
            $GeoId = 12
            $Timezone = "AUS Eastern Standard Time"
            $LanguageId = "0c09:00000409"
            $Language = "en-AU"
        }
        Default {
            # Australia
            $GeoId = 12
            $Timezone = "AUS Eastern Standard Time"
            $LanguageId = "0c09:00000409"
            $Language = "en-AU"
        }
    }

    #region Variables
    $languageXML = Join-Path -Path "$env:SystemRoot\Setup\Scripts" -ChildPath "language.xml"
    $languageXmlContent = @"
<gs:GlobalizationServices
    xmlns:gs="urn:longhornGlobalizationUnattend">
    <!--User List-->
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>
    </gs:UserList>
    <!-- user locale -->
    <gs:UserLocale>
        <gs:Locale Name="$Locale" SetAsCurrent="true"/>
    </gs:UserLocale>
    <!-- system locale -->
    <gs:SystemLocale Name="$Locale"/>
    <!-- GeoID -->
    <gs:LocationPreferences>
        <gs:GeoID Value="$GeoId"/>
    </gs:LocationPreferences>
    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="$Locale"/>
        <gs:MUIFallback Value="en-US"/>
    </gs:MUILanguagePreferences>
    <!-- input preferences -->
    <gs:InputPreferences>
        <gs:InputLanguageID Action="add" ID="$LanguageId" Default="true"/>
    </gs:InputPreferences>
</gs:GlobalizationServices>
"@

    $languagePS1 = Join-Path -Path "$env:SystemRoot\Setup\Scripts" -ChildPath "Set-Region.ps1"
    $languagePS1Content = @"
Import-Module -Name "International"
Set-WinSystemLocale -SystemLocale $Locale
Set-WinUserLanguageList -LanguageList $Locale -Force
Set-WinHomeLocation -GeoId $GeoId
Set-TimeZone -Id $Timezone
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:$languageXML"
"@

    <#
    $setupCompleteCMD = Join-Path -Path "$env:SystemRoot\Setup\Scripts" -ChildPath "SetupComplete.cmd"
    $setupCompleteContent = @"
$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File $languagePS1
"@
#>
    #endregion

    #region Set regional settings
    try {
        Import-Module -Name "International"
        Set-WinSystemLocale -SystemLocale $Locale
        Set-WinHomeLocation -GeoId $GeoId
        Set-TimeZone -Id $Timezone

        $LanguageList = Get-WinUserLanguageList
        $LanguageList.Add($Language)
        Set-WinUserLanguageList $LanguageList -Force
    }
    catch {
        Write-Host "ERR:: Failed to set locale to: $Locale with: $($_.Exception.Message)."
    }

    # Run language.xml
    try {
        $OutFile = Join-Path -Path $Path -ChildPath "language.xml"
        Out-File -FilePath $OutFile -InputObject $languageXmlContent -Encoding "utf8"
    }
    catch {
        Write-Host "ERR: Failed to create language file: $OutFile with: $($_.Exception.Message)."
    }

    # Set-Region.ps1
    try {
        & $env:SystemRoot\System32\control.exe "intl.cpl,,/f:$OutFile"
    }
    catch {
        Write-Host "ERR:: Failed to set regional settings with: $($_.Exception.Message)."
    }
    #endregion

    #region Set SetupComplete.cmd
    try {
        Out-File -FilePath $languageXML -InputObject $languageXmlContent -Encoding "utf8"
    }
    catch {
        Write-Host "ERR: Failed to create language file with: $($_.Exception.Message)."
    }

    try {
        Out-File -FilePath $languagePS1 -InputObject $languagePS1Content -Encoding "utf8"
    }
    catch {
        Write-Host "ERR: Failed to create set-language script with: $($_.Exception.Message)."
    }

    ##Disable Language Pack Cleanup##
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"

    # SetupComplete.CMD
    <#
    try {
        & takeown /f $setupCompleteCMD /a
        Out-File -FilePath $setupCompleteCMD -InputObject $setupCompleteContent -Append
    }
    catch {
        Write-Host "Failed to update set-language script: $setupCompleteCMD."
        Write-Error -Message $_.Exception.Message
    }#>
    #endregion
}

function Install-LanguageCapability ($Locale) {
    switch ($Locale) {
        "en-US" {
            # United States
            $Language = "en-US"
        }
        "en-GB" {
            # Great Britain
            $Language = "en-GB"
        }
        "en-AU" {
            # Australia
            $Language = "en-AU", "en-GB"
        }
        default {
            # Australia
            $Language = "en-AU", "en-GB"
        }
    }

    # Install Windows capability packages using Windows Update
    foreach ($lang in $Language) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding packages for [$lang]."
        $Capabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "Language*$lang*" }
        foreach ($Capability in $Capabilities) {
            try {
                Add-WindowsCapability -Online -Name $Capability.Name -LogLevel 2
            }
            catch {
                Write-Warning -Message " ERR: Failed to add capability: $($Capability.Name)."
            }
        }
    }
}
#endregion


#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks
if (Test-Path -Path env:Locale) {
    $Locale = $env:Locale
}
else {
    Write-Host "Can't find passed parameter, setting Locale to en-AU."
    $Locale = "en-AU"
}
Set-RegionSetting -Path $Path -Locale $Locale
#Install-LanguageCapability -Locale $Locale
