#description: Modifies the Specialize.xml file to prevent sysprep errors in AD-joined Windows 11 images
#tags: Sysprep, Image, Preview

<#
Notes: There is an issue with images created from Active Directory-joined Windows 11 VMs that prevents VMs
from booting. This script will remove the CryptoSysPrep_Specialize methods from the Specialize.xml file,
which is a workaround for this issue. It is unclear what unforeseen effects this modification may have.
Nerdio does not recommend using this workaround in a production environment. Microsoft is aware of the
issue with sysprep and will presumably provide a supported fix in the future.
#>

$fileName = "$env:SystemRoot\system32\Sysprep\ActionFiles\Specialize.xml"
$NewAcl = Get-Acl -Path $fileName

# Allow system to write
$identity = "NT AUTHORITY\SYSTEM"
$fileSystemRights = "FullControl"
$type = "Allow"
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName "System.Security.AccessControl.FileSystemAccessRule" -ArgumentList $fileSystemAccessRuleArgumentList
$NewAcl.SetAccessRule($fileSystemAccessRule)
Set-Acl -Path $fileName -AclObject $NewAcl

[xml]$SpecializeXml = [System.Xml.XmlDocument](Get-Content -Path $fileName)
# remove nodes
$SpecializeXml.SelectNodes("//sysprepModule") | ForEach-Object {
    if ($_.methodName -eq "CryptoSysPrep_Specialize") {
        $_.ParentNode.RemoveChild($_) | Out-Null
    }
}
$SpecializeXml.OuterXml | Out-File -FilePath $fileName
