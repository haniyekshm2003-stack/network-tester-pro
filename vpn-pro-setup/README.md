# 🚀 راهنمای کامل VPN حرفه‌ای

## 📊 وضعیت فعلی AWS

### ✅ کارهای انجام شده:

| کار                                | وضعیت         |
| ---------------------------------- | ------------- |
| 🗑️ حذف IP 79.125.75.182 (بلاک شده) | ✅ انجام شد   |
| 🗑️ حذف IP 46.51.141.95 (بلاک شده)  | ✅ انجام شد   |
| 🗑️ حذف سرور vpn-pro-server         | ✅ انجام شد   |
| 🆕 گرفتن IP جدید 54.74.125.123     | ✅ انجام شد   |
| 🆕 گرفتن IP جدید 54.228.90.224     | ✅ انجام شد   |
| 🔐 SSL Certificate برای tiki2k.com | ✅ درخواست شد |
| 🌐 Route 53 Hosted Zone            | ✅ ساخته شد   |

---

## 📍 IP های فعال

| IP                | وضعیت             | نوع        | کاربرد    |
| ----------------- | ----------------- | ---------- | --------- |
| **63.32.250.131** | 🟢 بهترین (129ms) | Elastic IP | سرور اصلی |
| **108.128.15.3**  | 🟢 فعال (150ms)   | Elastic IP | بکاپ 1    |
| **34.247.23.138** | 🟢 فعال (148ms)   | Elastic IP | بکاپ 2    |
| **54.74.125.123** | 🆕 جدید           | Elastic IP | اضافی     |
| **54.228.90.224** | 🆕 جدید           | Elastic IP | اضافی     |

---

## 🖥️ سرور فعال

| مشخصات          | مقدار                  |
| --------------- | ---------------------- |
| **Instance ID** | i-0e6df7694b21975d3    |
| **نام**         | VPN-Server-Netherlands |
| **نوع**         | t3.xlarge              |
| **IP اصلی**     | 108.128.15.3           |
| **منطقه**       | eu-west-1 (ایرلند)     |
| **کلید SSH**    | vpn-server-key         |
| **وضعیت**       | 🟢 Running             |

---

## 🔐 اطلاعات AWS

```
Account ID: 982389017724
Username: tiki2k
Region: eu-west-1
Access Key: AKIA6JOXSZR6PFSCSUNA
```

---

## 🌐 اطلاعات Cloudflare

```
Domain: tiki2k.com
Zone ID: a16e32a98e20cd2e03da2d50682f38b0
Account ID: 31b99eb61828a98ac16f8dad92c0d22d

⚠️ نیاز به ایمیل صحیح Cloudflare برای تنظیم DNS
```

---

## 📜 SSL Certificate

```
ARN: arn:aws:acm:us-east-1:982389017724:certificate/c4959c14-cc94-47eb-a4ec-538e9e00a93a
Domain: tiki2k.com + *.tiki2k.com
Status: Pending Validation

برای تأیید، این رکورد DNS رو اضافه کن:
Type: CNAME
Name: _ca421f93d37eb7d67472f493983a8c6f.tiki2k.com
Value: _c3523ad9d39f30734f111e832adbf8fa.jkddzztszm.acm-validations.aws
```

---

## 🛠️ مراحل نصب VPN

### مرحله 1: دانلود کلید SSH

1. برو به [AWS Console](https://console.aws.amazon.com/ec2/)
2. EC2 > Key Pairs
3. کلید `vpn-server-key` رو دانلود کن

### مرحله 2: اتصال به سرور

```bash
# از لینوکس/مک
chmod 400 vpn-server-key.pem
ssh -i vpn-server-key.pem ubuntu@108.128.15.3

# از ویندوز با PuTTY
# کلید رو به ppk تبدیل کن
```

### مرحله 3: نصب Xray

```bash
# روی سرور اجرا کن:
wget -O install.sh https://raw.githubusercontent.com/haniyekshm2003-stack/network-tester-pro/main/vpn-pro-setup/install-xray-pro.sh
chmod +x install.sh
sudo ./install.sh
```

### مرحله 4: کپی کانفیگ‌ها

بعد از نصب، لینک‌های اشتراک نمایش داده می‌شن که می‌تونی در:

- **v2rayNG** (اندروید)
- **v2rayN** (ویندوز)
- **Clash Verge** (همه پلتفرم‌ها)
- **Nekoray** (لینوکس/مک)

کپی کنی.

---

## 🔗 پروتکل‌های پیشنهادی

| پروتکل            | پورت | سرعت       | پایداری    | ضد شناسایی |
| ----------------- | ---- | ---------- | ---------- | ---------- |
| **VLESS Reality** | 443  | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| VLESS WebSocket   | 8443 | ⭐⭐⭐⭐   | ⭐⭐⭐⭐⭐ | ⭐⭐⭐     |
| Trojan WebSocket  | 2083 | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   | ⭐⭐⭐⭐   |
| VMess gRPC        | 2053 | ⭐⭐⭐⭐   | ⭐⭐⭐     | ⭐⭐⭐     |

**توصیه:** از **VLESS Reality** استفاده کن - سریع‌ترین و غیرقابل شناسایی‌ترین!

---

## 💰 هزینه‌های ماهانه

| سرویس                 | هزینه         |
| --------------------- | ------------- |
| EC2 t3.xlarge (24/7)  | ~$122         |
| Elastic IPs (5 عدد)   | ~$18          |
| Route 53              | ~$0.50        |
| Data Transfer (100GB) | ~$9           |
| **مجموع**             | **~$150/ماه** |

---

## 📞 پشتیبانی

اگر مشکلی داشتی:

1. چک کن سرور روشنه: `aws ec2 describe-instances`
2. چک کن Xray فعاله: `sudo systemctl status xray`
3. لاگ‌ها رو ببین: `sudo journalctl -u xray -f`

---

## 📁 فایل‌های مهم

```
/workspaces/.codespaces/vpn-pro-setup/
├── install-xray-pro.sh      # اسکریپت نصب Xray
├── multi-ip-manager.sh      # مدیریت چند IP
├── remote-installer.sh      # نصب از راه دور
└── README.md                # این راهنما

روی سرور:
/root/vpn-configs/
├── subscription.txt         # لینک‌های اشتراک
└── config-info.txt          # اطلاعات کامل
```

---

## ⚡ دستورات سریع

```bash
# وضعیت سرویس
sudo systemctl status xray

# ریستارت
sudo systemctl restart xray

# لاگ‌ها
sudo tail -f /var/log/xray/access.log

# تست پورت
netstat -tuln | grep 443
```

---

**آخرین بروزرسانی:** 28 ژانویه 2026
