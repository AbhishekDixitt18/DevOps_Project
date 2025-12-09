<#
Generate an Ansible inventory file from Terraform outputs.

Usage:
  .\scripts\generate_ansible_inventory.ps1 -PrivateKeyPath 'C:\path\to\master-key.pem' -OutFile '.\ansible\inventory.ini'

Requirements:
  - `terraform` must be on PATH and `terraform init` should have been run.
  - `-PrivateKeyPath` should point to your PEM file used for instances.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PrivateKeyPath,
    [string]$OutFile = "$PSScriptRoot\..\ansible\inventory.ini"
)

if (-not (Test-Path $PrivateKeyPath)) {
    Write-Error "Private key not found at '$PrivateKeyPath'"
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir '..')

$tfJson = terraform output -json public_ips 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tfJson)) {
    Write-Error "Failed to get 'public_ips' from terraform output. Ensure you run this from the repo root and that terraform init has been executed."
    exit 1
}

$data = $tfJson | ConvertFrom-Json
$ips = $data.value
if (-not $ips) { Write-Error "No public IPs found"; exit 1 }

$lines = @()
$lines += "[grafana_prometheus]"
for ($i=0; $i -lt $ips.Count; $i++) {
    $ip = $ips[$i]
    $lines += "$ip ansible_user=ubuntu ansible_ssh_private_key_file=$PrivateKeyPath"
}

$lines | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Wrote inventory with $($ips.Count) hosts to $OutFile"
