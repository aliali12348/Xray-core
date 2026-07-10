#!/bin/sh

PORT=${PORT:-8080}

# ساخت UUID رندوم در صورت عدم وجود
if [ -z "$UUID" ]; then
  UUID=$(cat /proc/sys/kernel/random/uuid)
fi

PATH_SECRET=${PATH_SECRET:-"/vless-ws"}

echo "=================================================="
echo "DEPLOYING XRAY CORE..."
echo "PORT: $PORT"
echo "UUID: $UUID"
echo "PATH: $PATH_SECRET"
echo "=================================================="

# تزریق دقیق متغیرها به داخل فایل index.html برای تولید QR Code
sed -i "s/{{UUID}}/$UUID/g" /var/www/html/index.html
sed -i "s|{{PATH}}|$PATH_SECRET|g" /var/www/html/index.html

# ساخت خودکار فایل تنظیمات Xray
cat << EOF > /etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "$UUID", "level": 0 } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$PATH_SECRET" }
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

# اجرای وب‌سرور برای نمایش سایت و کد QR
busybox httpd -p 80 -h /var/www/html &

# اجرای هسته اصلی پروکسی
exec xray run -c /etc/xray/config.json
