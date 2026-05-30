Param(
    [Parameter(Mandatory=$false)]
    [string]$ClientId = "<YOUR-CLIENT-ID>",

    [Parameter(Mandatory=$false)]
    [string]$TenantId = "common",

    [Parameter(Mandatory=$false)]
    [string[]]$Scopes = @("User.Read")
)

# Ensure MSAL.PS is available
if (-not (Get-Module -ListAvailable -Name MSAL.PS)) {
    Write-Host "Installing MSAL.PS module (current user)..."
    Install-Module -Name MSAL.PS -Scope CurrentUser -Force -AllowClobber
}

Import-Module MSAL.PS -ErrorAction Stop

Write-Host "Acquiring token for client:$ClientId tenant:$TenantId scopes:$($Scopes -join ',')"

# Interactive flow uses system browser and token cache (enables SSO across runs)
$token = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Scopes $Scopes -Interactive

if ($null -ne $token -and $token.AccessToken) {
    Write-Host "Access token acquired. Expires on: $($token.ExpiresOn)"

    $out = [PSCustomObject]@{
        AccessToken = $token.AccessToken
        ExpiresOn   = $token.ExpiresOn
        Account     = $token.Account
        TenantId    = $TenantId
        Scopes      = $Scopes -join ' '
    }

    $outPath = Join-Path -Path $PSScriptRoot -ChildPath "sso_token.json"
    $out | ConvertTo-Json -Depth 5 | Out-File -FilePath $outPath -Encoding utf8
    Write-Host "Token written to: $outPath"
} else {
    Write-Error "Failed to acquire token."
}

<#
Notes:
- Register a public client app in Entra ID and use its ClientId here.
- For native/desktop apps, set Redirect URI to: https://login.microsoftonline.com/common/oauth2/nativeclient
- This script uses interactive browser-based auth; MSAL caches tokens for SSO across runs.
#>