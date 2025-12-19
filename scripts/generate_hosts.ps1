<#
Generate an `aws_hosts` file from Terraform outputs.

Usage:
  1. Run from the repository root (where your terraform files live):
       .\scripts\generate_hosts.ps1
  2. Or specify an output file path:
       .\scripts\generate_hosts.ps1 -OutFile 'C:\temp\aws_hosts'

This script requires `terraform` on PATH and that `terraform init` has been run.
#>

param(
    [string]$OutFile = "$PSScriptRoot\..\aws_hosts"
)

# Move to repository root (parent of scripts folder)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir '..')

# Get terraform output for instance_public_ips in JSON
$tfJson = terraform output -json instance_public_ips 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tfJson)) {
    Write-Error "Failed to get 'instance_public_ips' from terraform output. Ensure you run this from the repo root and that terraform init has been executed."
    exit 1
}

$data = $tfJson | ConvertFrom-Json
# terraform -json output includes a 'value' property
$ips = $data.value
if (-not $ips) {
    Write-Error "No public IPs found in terraform output."
    exit 1
}

$lines = @()
$lines += "# AWS hosts file (generated)"
$lines += "# Generated: $(Get-Date -Format o)"
$lines += "# Format: <IP> <hostname>"
$lines += ""

for ($i = 0; $i -lt $ips.Count; $i++) {
    $ip = $ips[$i]
    $hostname = "tf-example-$($i + 1)"
    $lines += "$ip $hostname"
}

# Write to file
$fullOut = Resolve-Path -Path $OutFile -ErrorAction SilentlyContinue
if (-not $fullOut) {
    $parent = Split-Path -Parent $OutFile
    if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
}

$lines | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Wrote $($ips.Count) entries to '$OutFile'"