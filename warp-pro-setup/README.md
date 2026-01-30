# 🚀 WARP Pro Setup - راهنمای کامل

## 📋 فهرست
- [نصب سریع](#نصب-سریع)
- [فایل‌های کانفیگ](#فایلهای-کانفیگ)
- [روش‌های مختلف اتصال](#روشهای-مختلف-اتصال)
- [عیب‌یابی](#عیب‌یابی)

---

## 🎯 نصب سریع

```bash
# اجرای اسکریپت اصلی
cd /workspaces/network-tester-pro/warp-pro-setup
chmod +x *.sh
./master-setup.sh
```

یا برای نصب خودکار کامل:
```bash
./master-setup.sh  # گزینه 5 را انتخاب کنید
```

---

## 📁 فایل‌های کانفیگ

### بهترین IP‌ها (از تست شما)
| IP | سرعت دانلود | تاخیر |
|---|---|---|
| 198.41.217.60 | 20.75 MB/s | 112ms |
| 172.67.191.73 | 20.22 MB/s | 114ms |
| 162.159.14.253 | 17.48 MB/s | 111ms |
| 172.64.67.111 | 17.03 MB/s | 111ms |
| 104.16.160.140 | 13.98 MB/s | 111ms |

### پورت‌های پیشنهادی
- `2408` - پورت اصلی WARP
- `443` - HTTPS استاندارد
- `2053` - DNS over TLS
- `8443` - HTTPS جایگزین

---

## 🔌 روش‌های مختلف اتصال

### 1️⃣ WireGuard (پیشنهادی)
```bash
# نصب WireGuard
sudo apt install wireguard wireguard-tools

# کپی کانفیگ
sudo cp ~/.warp-pro/warp.conf /etc/wireguard/

# اتصال
sudo wg-quick up warp

# قطع اتصال
sudo wg-quick down warp
```

### 2️⃣ WARP Client رسمی
```bash
./install-warp-client.sh

# اتصال
warp-cli connect

# قطع
warp-cli disconnect

# وضعیت
warp-cli status
```

### 3️⃣ Cloudflare Tunnel (Zero Trust)
```bash
./cloudflare-tunnel-setup.sh

# بعد از login
cloudflared tunnel run iran-bypass-tunnel
```

### 4️⃣ Xray/V2Ray
کانفیگ آماده در: `configs/xray-warp-config.json`

```bash
# با Xray
xray run -c configs/xray-warp-config.json

# با V2Ray
v2ray run -c configs/xray-warp-config.json
```

---

## 🔧 اطلاعات Cloudflare شما

| پارامتر | مقدار |
|---|---|
| **Domain** | tiki2k.com |
| **Email** | H.keshmiri2003@gmail.com |
| **Zone ID** | a16e32a98e20cd2e03da2d50682f38b0 |
| **Account ID** | 31b99eb61828a98ac16f8dad92c0d22d |

---

## 🛠️ عیب‌یابی

### مشکل: اتصال برقرار نمی‌شود
```bash
# تست IP جدید
./cloudflare-ip-scanner.sh

# آپدیت endpoint در کانفیگ
nano ~/.warp-pro/warp.conf
```

### مشکل: سرعت پایین
```bash
# تست پورت‌های مختلف
# در فایل warp.conf:
# Endpoint = 198.41.217.60:443
# Endpoint = 198.41.217.60:2053
# Endpoint = 198.41.217.60:8443
```

### مشکل: DNS کار نمی‌کند
```bash
# تنظیم DNS دستی
sudo nano /etc/resolv.conf
# nameserver 1.1.1.1
# nameserver 8.8.8.8
```

### تست اتصال
```bash
# چک کردن IP جدید
curl https://cloudflare.com/cdn-cgi/trace

# باید نشان دهد:
# warp=on
# loc=US (یا هر کشور دیگر غیر از IR)
```

---

## ⚠️ نکات مهم

1. **کلیدهای API را تغییر دهید** - کلیدهای AWS و Cloudflare که به اشتراک گذاشتید باید فوراً تغییر کنند

2. **بکاپ بگیرید** - از فایل‌های کانفیگ بکاپ داشته باشید:
   ```bash
   cp -r ~/.warp-pro ~/warp-backup
   ```

3. **آپدیت منظم** - هر چند وقت یکبار IP‌های جدید اسکن کنید:
   ```bash
   ./cloudflare-ip-scanner.sh
   ```

---

## 📱 استفاده در برنامه‌های دیگر

### Nekoray / Nekobox
1. فایل `configs/xray-warp-config.json` را import کنید
2. یا WireGuard config را وارد کنید

### Clash / Clash Verge
```yaml
proxies:
  - name: "WARP"
    type: wireguard
    server: 198.41.217.60
    port: 2408
    ip: 172.16.0.2
    private-key: YOUR_PRIVATE_KEY
    public-key: bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
    udp: true
    mtu: 1280
```

### Hiddify
1. WireGuard config را import کنید
2. یا از لینک WARP استفاده کنید

---

## 🎉 موفق باشید!

اگر سوالی داشتید، تست IP جدید بزنید یا endpoint را عوض کنید.

**Created by WARP Pro Setup** 🚀
