function Install-Font {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [System.String] $Path
    )

    begin {
        $Context.Log("Load assembly: PresentationCore")
        Add-Type -AssemblyName "PresentationCore"

        # Get the font files in the target path
        $FontFiles = Get-ChildItem -Path $Path -Include "*.ttf", "*.otf" -Recurse
        $Context.Log("Found $($FontFiles.Count) font files in path: $Path")
    }

    process {
        foreach ($Font in $FontFiles) {
            try {
                # Load the font file
                $Context.Log("Load font: $($Font.FullName)")
                $Gt = [Windows.Media.GlyphTypeface]::New($Font.FullName)

                # Get the font family name
                $FamilyName = $Gt.Win32FamilyNames['en-US']
                if ($null -eq $FamilyName) {
                    $FamilyName = $Gt.Win32FamilyNames.Values.Item(0)
                }

                # Get the font face name
                $FaceName = $Gt.Win32FaceNames['en-US']
                if ($null -eq $FaceName) {
                    $FaceName = $Gt.Win32FaceNames.Values.Item(0)
                }

                # Add the font and get the font name
                $FontName = ("$FamilyName $FaceName").Trim()
                switch ($Font.Extension) {
                    ".ttf" { $FontName = "$FontName (TrueType)" }
                    ".otf" { $FontName = "$FontName (OpenType)" }
                }

                $Context.Log("Installing font: $FontName")
                $Context.Log("Copy font file: $($Font.Name)")
                Copy-Item -Path $Font.FullName -Destination "$Env:SystemRoot\Fonts\$($Font.Name)" -Force

                $Context.Log("Add font to registry: $($Font.Name)")
                New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $Font.Name -Force | Out-Null

                # Dispose the font collection
                $Context.Log("Font installed successfully")
            }
            catch {
                $Context.Log($_.Exception.Message)
                throw $_
            }
            finally {
                Remove-Variable -Name "Gt"
            }
        }
    }
}

Install-Font -Path $PWD
$Context.Log("Install complete.")
