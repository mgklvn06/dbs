$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot "mpesa_backend"
$envFile = Join-Path $backendDir ".env"
$exampleEnvFile = Join-Path $backendDir ".env.example"

if (-not (Test-Path $envFile)) {
  Copy-Item $exampleEnvFile $envFile
  Write-Host "Created mpesa_backend/.env from .env.example. Fill Daraja credentials before STK push."
}

# Clear any process currently binding port 3000.
$listening = netstat -ano | Select-String ":3000"
foreach ($line in $listening) {
  $parts = ($line.ToString() -replace "\s+", " ").Trim().Split(" ")
  $portPid = $parts[-1]
  if ($portPid -match "^\d+$") {
    try {
      taskkill /PID $portPid /F | Out-Null
    } catch {
      # Ignore if process already stopped.
    }
  }
}

Push-Location $backendDir
try {
  if (-not (Test-Path (Join-Path $backendDir "node_modules"))) {
    npm.cmd install
  }
  node server.js
} finally {
  Pop-Location
}
