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
    [string]$KeyPath = "./lamp-key.pem",
    [switch]$EnableSsmDeploy,
    [string]$WebServerInstanceId,
    [string]$AwsAccessKeyId,
    [string]$AwsSecretAccessKey,
    [string]$AwsSessionToken,
    [string]$AwsRegion = "us-east-1"
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

Require-Value -Name "WebServerIp" -Value $WebServerIp
Require-Value -Name "DbHost" -Value $DbHost
Require-Value -Name "DbPassword" -Value $DbPassword

if ($EnableSsmDeploy) {
    Require-Value -Name "WebServerInstanceId" -Value $WebServerInstanceId
    Require-Value -Name "AwsAccessKeyId" -Value $AwsAccessKeyId
    Require-Value -Name "AwsSecretAccessKey" -Value $AwsSecretAccessKey
}

$keyContent = ""
if (-not $EnableSsmDeploy) {
    if (-not (Test-Path $KeyPath)) {
        throw "EC2 key file not found at path: $KeyPath"
    }

    $keyContent = Get-Content -Path $KeyPath -Raw
    if ([string]::IsNullOrWhiteSpace($keyContent)) {
        throw "EC2 key file is empty: $KeyPath"
    }
}

Write-Host "Setting repository secrets on $Repo ..." -ForegroundColor Cyan

$secretMap = @{
    WEB_SERVER_IP      = $WebServerIp
    DB_HOST            = $DbHost
    DB_NAME            = $DbName
    DB_USER            = $DbUser
    DB_PASSWORD        = $DbPassword
}

if (-not [string]::IsNullOrWhiteSpace($DockerhubUsername) -and -not [string]::IsNullOrWhiteSpace($DockerhubToken)) {
    $secretMap["DOCKERHUB_USERNAME"] = $DockerhubUsername
    $secretMap["DOCKERHUB_TOKEN"] = $DockerhubToken
}

if ($EnableSsmDeploy) {
    $secretMap["WEB_SERVER_INSTANCE_ID"] = $WebServerInstanceId
    $secretMap["AWS_ACCESS_KEY_ID"] = $AwsAccessKeyId
    $secretMap["AWS_SECRET_ACCESS_KEY"] = $AwsSecretAccessKey

    if (-not [string]::IsNullOrWhiteSpace($AwsSessionToken)) {
        $secretMap["AWS_SESSION_TOKEN"] = $AwsSessionToken
    }
}

foreach ($name in $secretMap.Keys) {
    $value = $secretMap[$name]
    $value | gh secret set $name --repo $Repo --body - | Out-Null
    Write-Host "  ✔ Secret set: $name"
}

if (-not $EnableSsmDeploy) {
    $keyContent | gh secret set EC2_SSH_KEY --repo $Repo --body - | Out-Null
    Write-Host "  ✔ Secret set: EC2_SSH_KEY"
}

gh variable set EC2_USER --repo $Repo --body $Ec2User | Out-Null
Write-Host "  ✔ Variable set: EC2_USER=$Ec2User"

gh variable set AWS_REGION --repo $Repo --body $AwsRegion | Out-Null
Write-Host "  ✔ Variable set: AWS_REGION=$AwsRegion"

if ($EnableSsmDeploy) {
    gh variable set USE_SSM_DEPLOY --repo $Repo --body "true" | Out-Null
    Write-Host "  ✔ Variable set: USE_SSM_DEPLOY=true"
} else {
    gh variable set USE_SSM_DEPLOY --repo $Repo --body "false" | Out-Null
    Write-Host "  ✔ Variable set: USE_SSM_DEPLOY=false"
}

Write-Host "Done. CI/CD secrets and variable are configured." -ForegroundColor Green
Write-Host "Next: push a new commit to main to trigger .github/workflows/deploy.yml" -ForegroundColor Green
