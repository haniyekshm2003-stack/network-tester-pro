# ═══════════════════════════════════════════════════════════════════════════════
#  🌐 AWS Network Scanner Pro - اسکنر حرفه‌ای شبکه AWS
#  نسخه: 2.0
#  تاریخ: January 2026
# ═══════════════════════════════════════════════════════════════════════════════

# تنظیمات رنگ‌ها
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# ═══════════════════════════════════════════════════════════════════════════════
# تعریف منابع AWS
# ═══════════════════════════════════════════════════════════════════════════════

$AWSResources = @{
    EC2Instances = @(
        @{ Name = "vpn-pro-server"; IP = "79.125.75.182"; Type = "t3.xlarge"; Region = "Ireland"; Flag = "IE" }
        @{ Name = "VPN-Server-Netherlands"; IP = "108.128.15.3"; Type = "t3.xlarge"; Region = "Netherlands"; Flag = "NL" }
    )
    
    ElasticIPs = @(
        @{ IP = "79.125.75.182"; Status = "In Use"; Name = "vpn-pro-server" }
        @{ IP = "108.128.15.3"; Status = "In Use"; Name = "VPN-Netherlands" }
        @{ IP = "46.51.141.95"; Status = "In Use"; Name = "Elastic-1" }
        @{ IP = "34.247.23.138"; Status = "In Use"; Name = "Elastic-2" }
        @{ IP = "63.32.250.131"; Status = "In Use"; Name = "Elastic-3" }
    )
    
    PrivateIPs = @(
        "172.31.30.165",
        "172.31.19.82",
        "172.31.28.209",
        "172.31.24.89",
        "172.31.22.89",
        "172.31.28.154",
        "172.31.25.97"
    )
    
    SecurityGroups = @(
        @{ Name = "vpn-pro-sg"; Description = "All ports open" }
        @{ Name = "vpn-sg"; Description = "VPN Security Group" }
        @{ Name = "vpn-server-sg"; Description = "VPN Server Security" }
        @{ Name = "mtproxy-sg"; Description = "MTProxy Security" }
    )
    
    VPC = @{
        ID = "vpc-0d40db6748dac6cd1"
        CIDR = "172.31.0.0/16"
        Region = "eu-west-1 (Ireland)"
        Account = "982389017724"
    }
    
    Subnets = @(
        @{ AZ = "eu-west-1a"; CIDR = "172.31.16.0/20" }
        @{ AZ = "eu-west-1b"; CIDR = "172.31.32.0/20" }
        @{ AZ = "eu-west-1c"; CIDR = "172.31.0.0/20" }
    )
}

# پورت‌های مهم برای تست
$PortsToTest = @(
    @{ Port = 22; Name = "SSH" }
    @{ Port = 80; Name = "HTTP" }
    @{ Port = 443; Name = "HTTPS" }
    @{ Port = 1194; Name = "OpenVPN" }
    @{ Port = 51820; Name = "WireGuard" }
    @{ Port = 8080; Name = "Proxy" }
    @{ Port = 3128; Name = "Squid" }
    @{ Port = 1080; Name = "SOCKS" }
    @{ Port = 8443; Name = "Alt-HTTPS" }
    @{ Port = 2083; Name = "V2Ray" }
)

# ═══════════════════════════════════════════════════════════════════════════════
# توابع کمکی
# ═══════════════════════════════════════════════════════════════════════════════

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color -NoNewline
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-SubHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "───────────────────────────────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "───────────────────────────────────────────────────────────────" -ForegroundColor DarkCyan
}

function Get-MyPublicIP {
    Write-Host "  در حال دریافت IP عمومی شما..." -ForegroundColor Gray
    
    $apis = @(
        "https://api.ipify.org",
        "https://icanhazip.com",
        "https://ifconfig.me/ip",
        "https://checkip.amazonaws.com"
    )
    
    foreach ($api in $apis) {
        try {
            $ip = (Invoke-WebRequest -Uri $api -TimeoutSec 5 -UseBasicParsing).Content.Trim()
            if ($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                return $ip
            }
        } catch {
            continue
        }
    }
    return "Unknown"
}

function Get-IPInfo {
    param([string]$IP)
    
    try {
        $info = Invoke-RestMethod -Uri "http://ip-api.com/json/$IP" -TimeoutSec 5
        return $info
    } catch {
        return $null
    }
}

function Test-PingIP {
    param(
        [string]$IP,
        [int]$Count = 4
    )
    
    $results = @{
        Success = $false
        AvgPing = 0
        MinPing = 0
        MaxPing = 0
        PacketLoss = 100
        Pings = @()
    }
    
    try {
        $pingResults = Test-Connection -ComputerName $IP -Count $Count -ErrorAction SilentlyContinue
        
        if ($pingResults) {
            $successCount = ($pingResults | Where-Object { $_.StatusCode -eq 0 }).Count
            $results.PacketLoss = [math]::Round((($Count - $successCount) / $Count) * 100)
            
            $times = $pingResults | Where-Object { $_.StatusCode -eq 0 } | ForEach-Object { $_.ResponseTime }
            
            if ($times.Count -gt 0) {
                $results.Success = $true
                $results.AvgPing = [math]::Round(($times | Measure-Object -Average).Average)
                $results.MinPing = ($times | Measure-Object -Minimum).Minimum
                $results.MaxPing = ($times | Measure-Object -Maximum).Maximum
                $results.Pings = $times
            }
        }
    } catch {
        # Ping failed
    }
    
    return $results
}

function Test-PortOpen {
    param(
        [string]$IP,
        [int]$Port,
        [int]$Timeout = 2000
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($IP, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($wait) {
            try {
                $tcpClient.EndConnect($connect)
                $tcpClient.Close()
                return $true
            } catch {
                return $false
            }
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}

function Get-PingColor {
    param([int]$Ping)
    
    if ($Ping -lt 100) { return "Green" }
    elseif ($Ping -lt 200) { return "Yellow" }
    elseif ($Ping -lt 300) { return "DarkYellow" }
    else { return "Red" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# شروع اسکریپت
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║                                                               ║" -ForegroundColor Magenta
Write-Host "  ║      🌐 AWS Network Scanner Pro                              ║" -ForegroundColor Magenta
Write-Host "  ║      اسکنر حرفه‌ای شبکه AWS                                  ║" -ForegroundColor Magenta
Write-Host "  ║                                                               ║" -ForegroundColor Magenta
Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$startTime = Get-Date

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۱: اطلاعات IP شما
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "📍 اطلاعات IP شما"

$myIP = Get-MyPublicIP
$myInfo = Get-IPInfo -IP $myIP

Write-Host "  🌐 IP Address:    " -NoNewline -ForegroundColor Gray
Write-Host $myIP -ForegroundColor Cyan

if ($myInfo) {
    Write-Host "  🏳️ Country:       " -NoNewline -ForegroundColor Gray
    $countryColor = if ($myInfo.countryCode -eq "IR") { "Red" } else { "Green" }
    Write-Host "$($myInfo.country) ($($myInfo.countryCode))" -ForegroundColor $countryColor
    
    Write-Host "  🏙️ City:          " -NoNewline -ForegroundColor Gray
    Write-Host $myInfo.city -ForegroundColor White
    
    Write-Host "  📡 ISP:           " -NoNewline -ForegroundColor Gray
    Write-Host $myInfo.isp -ForegroundColor White
    
    Write-Host "  🔒 VPN Status:    " -NoNewline -ForegroundColor Gray
    if ($myInfo.countryCode -eq "IR") {
        Write-Host "❌ غیرفعال (IP ایران)" -ForegroundColor Red
    } else {
        Write-Host "✅ فعال ($($myInfo.country))" -ForegroundColor Green
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۲: منابع AWS
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "☁️ منابع AWS شما"

Write-SubHeader "📦 EC2 Instances"
foreach ($instance in $AWSResources.EC2Instances) {
    Write-Host "  • " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($instance.Name)" -NoNewline -ForegroundColor Yellow
    Write-Host " | " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($instance.IP)" -NoNewline -ForegroundColor Cyan
    Write-Host " | " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($instance.Type)" -NoNewline -ForegroundColor Gray
    Write-Host " | " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($instance.Region)" -ForegroundColor Green
}

Write-SubHeader "🌐 Elastic IPs"
foreach ($eip in $AWSResources.ElasticIPs) {
    Write-Host "  • " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($eip.IP)" -NoNewline -ForegroundColor Cyan
    Write-Host " → " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($eip.Name)" -NoNewline -ForegroundColor Yellow
    Write-Host " [" -NoNewline -ForegroundColor DarkGray
    Write-Host "$($eip.Status)" -NoNewline -ForegroundColor Green
    Write-Host "]" -ForegroundColor DarkGray
}

Write-SubHeader "🔒 Private IPs"
$privateIPsLine = $AWSResources.PrivateIPs -join ", "
Write-Host "  $privateIPsLine" -ForegroundColor Gray

Write-SubHeader "🛡️ Security Groups"
foreach ($sg in $AWSResources.SecurityGroups) {
    Write-Host "  • " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($sg.Name)" -NoNewline -ForegroundColor Yellow
    Write-Host " - $($sg.Description)" -ForegroundColor Gray
}

Write-SubHeader "🌐 VPC Info"
Write-Host "  VPC ID:   $($AWSResources.VPC.ID)" -ForegroundColor Gray
Write-Host "  CIDR:     $($AWSResources.VPC.CIDR)" -ForegroundColor Gray
Write-Host "  Region:   $($AWSResources.VPC.Region)" -ForegroundColor Gray
Write-Host "  Account:  $($AWSResources.VPC.Account)" -ForegroundColor Gray

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۳: تست پینگ به سرورهای AWS
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "📡 تست اتصال به سرورهای AWS"

$pingResults = @()

Write-Host ""
Write-Host "  IP Address          Server Name              Ping      Status" -ForegroundColor White
Write-Host "  ─────────────────   ──────────────────────   ───────   ──────────" -ForegroundColor DarkGray

foreach ($eip in $AWSResources.ElasticIPs) {
    Write-Host "  $($eip.IP.PadRight(18))" -NoNewline -ForegroundColor Cyan
    Write-Host "$($eip.Name.PadRight(24))" -NoNewline -ForegroundColor Yellow
    Write-Host "..." -NoNewline -ForegroundColor Gray
    
    $pingTest = Test-PingIP -IP $eip.IP -Count 3
    
    # Clear the "..." and write result
    Write-Host "`b`b`b" -NoNewline
    
    if ($pingTest.Success) {
        $pingColor = Get-PingColor -Ping $pingTest.AvgPing
        Write-Host "$($pingTest.AvgPing.ToString().PadLeft(4))ms   " -NoNewline -ForegroundColor $pingColor
        Write-Host "✅ قابل دسترسی" -ForegroundColor Green
        
        $pingResults += @{
            IP = $eip.IP
            Name = $eip.Name
            Ping = $pingTest.AvgPing
            Status = "OK"
            PacketLoss = $pingTest.PacketLoss
        }
    } else {
        Write-Host " N/A     " -NoNewline -ForegroundColor Red
        Write-Host "❌ غیرقابل دسترسی" -ForegroundColor Red
        
        $pingResults += @{
            IP = $eip.IP
            Name = $eip.Name
            Ping = 0
            Status = "FAILED"
            PacketLoss = 100
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۴: تست پورت‌ها
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "🔌 تست پورت‌های سرورهای اصلی"

$mainServers = $AWSResources.EC2Instances

foreach ($server in $mainServers) {
    Write-SubHeader "$($server.Name) ($($server.IP))"
    
    $openPorts = @()
    $closedPorts = @()
    
    foreach ($portInfo in $PortsToTest) {
        Write-Host "  Testing port $($portInfo.Port) ($($portInfo.Name))..." -NoNewline -ForegroundColor Gray
        
        $isOpen = Test-PortOpen -IP $server.IP -Port $portInfo.Port -Timeout 2000
        
        Write-Host "`r" -NoNewline
        
        if ($isOpen) {
            $openPorts += $portInfo
            Write-Host "  ✅ " -NoNewline -ForegroundColor Green
            Write-Host "Port $($portInfo.Port.ToString().PadRight(5))" -NoNewline -ForegroundColor Cyan
            Write-Host " ($($portInfo.Name))" -NoNewline -ForegroundColor Yellow
            Write-Host " - OPEN" -ForegroundColor Green
        } else {
            $closedPorts += $portInfo
        }
    }
    
    if ($closedPorts.Count -gt 0) {
        Write-Host ""
        Write-Host "  پورت‌های بسته/فیلتر: " -NoNewline -ForegroundColor DarkGray
        $closedList = ($closedPorts | ForEach-Object { "$($_.Port)" }) -join ", "
        Write-Host $closedList -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "  📊 خلاصه: " -NoNewline -ForegroundColor White
    Write-Host "$($openPorts.Count)" -NoNewline -ForegroundColor Green
    Write-Host " باز | " -NoNewline -ForegroundColor Gray
    Write-Host "$($closedPorts.Count)" -NoNewline -ForegroundColor Red
    Write-Host " بسته" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۵: تست سایت‌های معروف
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "🌍 تست دسترسی به سایت‌های معروف"

$sitesToTest = @(
    @{ Name = "Google"; Host = "google.com" }
    @{ Name = "YouTube"; Host = "youtube.com" }
    @{ Name = "Twitter/X"; Host = "twitter.com" }
    @{ Name = "Telegram"; Host = "telegram.org" }
    @{ Name = "Instagram"; Host = "instagram.com" }
    @{ Name = "WhatsApp"; Host = "whatsapp.com" }
    @{ Name = "Discord"; Host = "discord.com" }
    @{ Name = "GitHub"; Host = "github.com" }
    @{ Name = "OpenAI"; Host = "openai.com" }
    @{ Name = "Cloudflare"; Host = "cloudflare.com" }
)

Write-Host ""
Write-Host "  Site             Status         Ping" -ForegroundColor White
Write-Host "  ───────────────  ─────────────  ────────" -ForegroundColor DarkGray

foreach ($site in $sitesToTest) {
    Write-Host "  $($site.Name.PadRight(15))" -NoNewline -ForegroundColor Yellow
    
    $pingTest = Test-PingIP -IP $site.Host -Count 2
    
    if ($pingTest.Success) {
        Write-Host "  ✅ دسترسی دارد" -NoNewline -ForegroundColor Green
        $pingColor = Get-PingColor -Ping $pingTest.AvgPing
        Write-Host "   $($pingTest.AvgPing)ms" -ForegroundColor $pingColor
    } else {
        Write-Host "  ❌ فیلتر/بلاک" -NoNewline -ForegroundColor Red
        Write-Host "   N/A" -ForegroundColor DarkGray
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۶: تست DNS
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "🔍 تست DNS Servers"

$dnsServers = @(
    @{ Name = "Google DNS"; IP = "8.8.8.8" }
    @{ Name = "Google DNS 2"; IP = "8.8.4.4" }
    @{ Name = "Cloudflare"; IP = "1.1.1.1" }
    @{ Name = "Cloudflare 2"; IP = "1.0.0.1" }
    @{ Name = "Shecan"; IP = "178.22.122.100" }
    @{ Name = "Electro"; IP = "78.157.42.100" }
    @{ Name = "403.online"; IP = "10.202.10.202" }
    @{ Name = "Radar Game"; IP = "10.202.10.10" }
)

Write-Host ""
Write-Host "  DNS Server       IP              Status      Ping" -ForegroundColor White
Write-Host "  ───────────────  ──────────────  ──────────  ────────" -ForegroundColor DarkGray

foreach ($dns in $dnsServers) {
    Write-Host "  $($dns.Name.PadRight(15))" -NoNewline -ForegroundColor Yellow
    Write-Host "  $($dns.IP.PadRight(14))" -NoNewline -ForegroundColor Cyan
    
    $pingTest = Test-PingIP -IP $dns.IP -Count 2
    
    if ($pingTest.Success) {
        Write-Host "  ✅ OK" -NoNewline -ForegroundColor Green
        $pingColor = Get-PingColor -Ping $pingTest.AvgPing
        Write-Host "       $($pingTest.AvgPing)ms" -ForegroundColor $pingColor
    } else {
        Write-Host "  ❌ FAIL" -NoNewline -ForegroundColor Red
        Write-Host "     N/A" -ForegroundColor DarkGray
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# بخش ۷: خلاصه نتایج
# ═══════════════════════════════════════════════════════════════════════════════

Write-Header "📊 خلاصه نتایج"

$endTime = Get-Date
$duration = $endTime - $startTime

$successfulPings = ($pingResults | Where-Object { $_.Status -eq "OK" }).Count
$failedPings = ($pingResults | Where-Object { $_.Status -eq "FAILED" }).Count
$avgPing = 0
if ($successfulPings -gt 0) {
    $avgPing = [math]::Round(($pingResults | Where-Object { $_.Status -eq "OK" } | Measure-Object -Property Ping -Average).Average)
}

# Find best server
$bestServer = $pingResults | Where-Object { $_.Status -eq "OK" } | Sort-Object Ping | Select-Object -First 1

Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │                                                             │" -ForegroundColor Cyan
Write-Host "  │  📡 سرورهای قابل دسترسی:  " -NoNewline -ForegroundColor Cyan
Write-Host "$successfulPings از $($AWSResources.ElasticIPs.Count)".PadRight(30) -NoNewline -ForegroundColor Green
Write-Host "│" -ForegroundColor Cyan

Write-Host "  │  📈 میانگین پینگ:         " -NoNewline -ForegroundColor Cyan
$pingText = if ($avgPing -gt 0) { "${avgPing}ms" } else { "N/A" }
Write-Host "$pingText".PadRight(30) -NoNewline -ForegroundColor Yellow
Write-Host "│" -ForegroundColor Cyan

Write-Host "  │  ⭐ بهترین سرور:          " -NoNewline -ForegroundColor Cyan
$bestText = if ($bestServer) { "$($bestServer.Name) ($($bestServer.Ping)ms)" } else { "N/A" }
Write-Host "$bestText".PadRight(30) -NoNewline -ForegroundColor Green
Write-Host "│" -ForegroundColor Cyan

Write-Host "  │  ⏱️ زمان اجرا:            " -NoNewline -ForegroundColor Cyan
Write-Host "$([math]::Round($duration.TotalSeconds, 1)) ثانیه".PadRight(30) -NoNewline -ForegroundColor Gray
Write-Host "│" -ForegroundColor Cyan

Write-Host "  │                                                             │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════════════════════
# توصیه‌ها
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  💡 توصیه‌ها:" -ForegroundColor Yellow
Write-Host ""

if ($myInfo -and $myInfo.countryCode -eq "IR") {
    Write-Host "  ⚠️  شما با IP ایران متصل هستید. برای دسترسی بهتر از VPN استفاده کنید." -ForegroundColor Red
}

if ($bestServer) {
    Write-Host "  ✅ بهترین سرور برای اتصال: $($bestServer.Name) با پینگ $($bestServer.Ping)ms" -ForegroundColor Green
}

if ($successfulPings -eq 0) {
    Write-Host "  ❌ هیچ سروری قابل دسترسی نیست. اتصال اینترنت یا فایروال را بررسی کنید." -ForegroundColor Red
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  اسکن کامل شد! | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

# ذخیره نتایج در فایل
$reportPath = Join-Path $PSScriptRoot "network-scan-report.txt"
$report = @"
═══════════════════════════════════════════════════════════════
AWS Network Scanner Pro - گزارش اسکن
تاریخ: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
═══════════════════════════════════════════════════════════════

📍 اطلاعات شما:
   IP: $myIP
   کشور: $($myInfo.country) ($($myInfo.countryCode))
   شهر: $($myInfo.city)
   ISP: $($myInfo.isp)

📊 نتایج پینگ:
$($pingResults | ForEach-Object { "   $($_.IP) - $($_.Name): $($_.Ping)ms [$($_.Status)]" } | Out-String)

📈 خلاصه:
   سرورهای قابل دسترسی: $successfulPings از $($AWSResources.ElasticIPs.Count)
   میانگین پینگ: ${avgPing}ms
   بهترین سرور: $($bestServer.Name) ($($bestServer.Ping)ms)
   زمان اجرا: $([math]::Round($duration.TotalSeconds, 1)) ثانیه

═══════════════════════════════════════════════════════════════
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "  📄 گزارش ذخیره شد: $reportPath" -ForegroundColor Cyan
Write-Host ""
