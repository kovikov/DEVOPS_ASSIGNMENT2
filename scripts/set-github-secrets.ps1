param(
    [string]$Repo = "kovikov/DEVOPS_ASSIGNMENT2",
    [string]$DockerhubUsername,
    [string]$DockerhubToken,
    [string]$WebServerIp,
    [string]$DbHost,
    [string]$DbName = "lampdb",
    [string]$DbUser = "lampuser",
    [string]$DbPassword,
    [string]$Ec2User = "ubuntu",
    [string]$KeyPath = "./lamp-key.pem"
)

$ErrorActionPreference = "Stop"

function Require-Value {
    param(
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Missing required value: $Name"
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is not installed. Install it first: https://cli.github.com/"
}

Write-Host "Checking GitHub CLI authentication..." -ForegroundColor Cyan
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
}

Require-Value -Name "DockerhubUsername" -Value $DockerhubUsername
Require-Value -Name "DockerhubToken" -Value $DockerhubToken
Require-Value -Name "WebServerIp" -Value $WebServerIp
Require-Value -Name "DbHost" -Value $DbHost
Require-Value -Name "DbPassword" -Value $DbPassword

if (-not (Test-Path $KeyPath)) {
    throw "EC2 key file not found at path: $KeyPath"
}

$keyContent = Get-Content -Path $KeyPath -Raw
if ([string]::IsNullOrWhiteSpace($keyContent)) {
    throw "EC2 key file is empty: $KeyPath"
}

Write-Host "Setting repository secrets on $Repo ..." -ForegroundColor Cyan

$secretMap = @{
    DOCKERHUB_USERNAME = $DockerhubUsername
    DOCKERHUB_TOKEN    = $DockerhubToken
    WEB_SERVER_IP      = $WebServerIp
    DB_HOST            = $DbHost
    DB_NAME            = $DbName
    DB_USER            = $DbUser
    DB_PASSWORD        = $DbPassword
}

foreach ($name in $secretMap.Keys) {
    $value = $secretMap[$name]
    $value | gh secret set $name --repo $Repo --body - | Out-Null
    Write-Host "  ✔ Secret set: $name"
}

$keyContent | gh secret set EC2_SSH_KEY --repo $Repo --body - | Out-Null
Write-Host "  ✔ Secret set: EC2_SSH_KEY"

gh variable set EC2_USER --repo $Repo --body $Ec2User | Out-Null
Write-Host "  ✔ Variable set: EC2_USER=$Ec2User"

Write-Host "Done. CI/CD secrets and variable are configured." -ForegroundColor Green
Write-Host "Next: push a new commit to main to trigger .github/workflows/deploy.yml" -ForegroundColor Green
