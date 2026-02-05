$conns = Get-NetTCPConnection -LocalPort 3100 -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
}
Write-Host "Port 3100 cleared"
