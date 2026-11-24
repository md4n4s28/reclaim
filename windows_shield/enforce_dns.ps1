# Reclaim Desktop Shield - CleanBrowsing Family Filter DNS Enforcer
# Configures network adapters with CleanBrowsing Family Filter endpoints to block adult content at the DNS level.

$DnsIpv4 = @("185.228.168.168", "185.228.169.168")

Write-Host "Enforcing CleanBrowsing Family DNS on all active network adapters..." -ForegroundColor Cyan

try {
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $Adapters) {
        Write-Host "Configuring adapter: $($adapter.Name) ($($adapter.InterfaceDescription))"
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $DnsIpv4 -ErrorAction SilentlyContinue
    }
    
    # Flush DNS Resolver cache
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    ipconfig /flushdns | Out-Null
    Write-Host "CleanBrowsing Family DNS configured and DNS cache flushed." -ForegroundColor Green
} catch {
    Write-Warning "Could not update DNS settings on all adapters: $_"
}
