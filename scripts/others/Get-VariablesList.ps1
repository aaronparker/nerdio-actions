[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$params = @{
    Uri             = $SecureVars.VariablesList
    UseBasicParsing = $true
    ErrorAction     = "Stop"
}
$Variables = Invoke-RestMethod @params
