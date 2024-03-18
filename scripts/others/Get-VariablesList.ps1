[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$params = @{
    Uri             = $SecureVars.VariablesList
    UseBasicParsing = $true
    ErrorAction     = "Stop"
}
$Variables = Invoke-RestMethod @params
