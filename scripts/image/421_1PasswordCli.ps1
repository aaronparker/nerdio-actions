#description: Installs the latest 1Password CLI
#execution mode: Combined
#tags: Evergreen, 1Password

#Requires -Modules Evergreen
[System.String] $Path = "$Env:ProgramFiles\1Password CLI"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download - update when Evergreen supports 1Password CLI
$App = [PSCustomObject]@{
    Version = "2.23.0"
    URI     = "https://cache.agilebits.com/dist/1P/op2/pkg/v2.23.0/op_windows_amd64_v2.23.0.zip"
}
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
Remove-Item -Path $OutFile.FullName -Force -ErrorAction "SilentlyContinue"

# Add $Path to the system Path environment variable if it doesn't already exist
if ([System.Environment]::GetEnvironmentVariable($Env:Path) -match "1Password") {}
else {
    [System.Environment]::SetEnvironmentVariable("Path",
        [System.Environment]::GetEnvironmentVariable("Path",
            [System.EnvironmentVariableTarget]::Machine) + ";$Path",
        [System.EnvironmentVariableTarget]::Machine)
}
