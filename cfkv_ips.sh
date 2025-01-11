#!/bin/bash

# 从环境变量中获取 CF_DOMAIN 和 CF_TOKEN
CF_DOMAIN="${CF_DOMAIN}"
CF_TOKEN="${CF_TOKEN}"

FILENAME="$1"

BASE64_TEXT=$(head -n 65 "$FILENAME" | base64 -w 0)

URL="https://${CF_DOMAIN}/${FILENAME}?token=${CF_TOKEN}&b64=${BASE64_TEXT}"

# 使用 curl 发送请求
curl -s "$URL" &

echo "更新数据完成,倒数5秒后自动关闭窗口..."
sleep 5
exit
