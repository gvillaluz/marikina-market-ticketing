$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../MarikinaMarket.API'))
$emailSettings = @{}
foreach ($configName in @('appsettings.json', 'appsettings.Development.json')) {
    $configPath = Join-Path $projectRoot $configName
    if (Test-Path -LiteralPath $configPath) {
        $json = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        if ($json.Email) { foreach ($property in $json.Email.PSObject.Properties) { $emailSettings[$property.Name] = [string]$property.Value } }
    }
}
[xml]$projectXml = Get-Content -LiteralPath (Join-Path $projectRoot 'MarikinaMarket.API.csproj') -Raw
$secretId = [string]$projectXml.Project.PropertyGroup.UserSecretsId
$secretPath = Join-Path $env:APPDATA ('Microsoft/UserSecrets/' + $secretId + '/secrets.json')
if (Test-Path -LiteralPath $secretPath) {
    $secrets = Get-Content -LiteralPath $secretPath -Raw | ConvertFrom-Json
    foreach ($property in $secrets.PSObject.Properties) {
        if ($property.Name.StartsWith('Email:')) { $emailSettings[$property.Name.Substring(6)] = [string]$property.Value }
    }
}
foreach ($key in @('SmtpHost', 'SmtpPort', 'FromAddress', 'AppPassword')) {
    $override = [Environment]::GetEnvironmentVariable('Email__' + $key)
    if ($null -ne $override) { $emailSettings[$key] = $override }
}
$smtpPort = 0
$portValid = [int]::TryParse($emailSettings['SmtpPort'], [ref]$smtpPort) -and $smtpPort -gt 0 -and $smtpPort -le 65535
$result = [ordered]@{
    checkedAtUtc = [DateTime]::UtcNow.ToString('o')
    configuration = 'Local Development files, User Secrets and this process environment; running API overrides unconfirmed'
    smtpHost = $emailSettings['SmtpHost']; smtpPort = $smtpPort; configuredTls = 'StartTls'
    fromAddressPresent = -not [string]::IsNullOrWhiteSpace($emailSettings['FromAddress'])
    appPasswordPresent = -not [string]::IsNullOrWhiteSpace($emailSettings['AppPassword'])
    portValid = $portValid; dnsResolved = $false; tcpConnected = $false
    emailSent = $false; databaseAccessed = $false
}
try {
    if (-not $portValid -or [string]::IsNullOrWhiteSpace($emailSettings['SmtpHost'])) { throw 'Missing SMTP host or valid port' }
    $addresses = [Net.Dns]::GetHostAddresses($emailSettings['SmtpHost'])
    $result.dnsResolved = $addresses.Count -gt 0
    $socket = New-Object Net.Sockets.TcpClient
    try {
        $connection = $socket.ConnectAsync($emailSettings['SmtpHost'], $smtpPort)
        if (-not $connection.Wait(10000)) { $result.tcpResult = 'Timed out after 10 seconds' }
        else { $result.tcpConnected = $socket.Connected; $result.tcpResult = 'Connected; no SMTP authentication or message attempted' }
    } finally { $socket.Dispose() }
} catch { $result.failureType = $_.Exception.GetType().Name }
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'smtp-connectivity.json')
$result | ConvertTo-Json
