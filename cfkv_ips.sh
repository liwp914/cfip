#!/bin/bash

# 从环境变量中获取 CF_DOMAIN 和 CF_TOKEN
CF_DOMAIN="${CF_DOMAIN}"
CF_TOKEN="${CF_TOKEN}"

# 获取传入的所有文件名参数（假设在 GitHub Actions 中会传入多个文件名作为参数）
files=("$@")

# 循环处理每个文件
for FILENAME in "${files[@]}"; do
    # 判断文件是否存在，如果不存在则跳过该文件的处理
    if [ ! -f "$FILENAME" ]; then
        echo "文件 $FILENAME 不存在，跳过该文件的处理。"
        continue
    fi

    BASE64_TEXT=$(head -n 65 "$FILENAME" | base64 -w 0)
    FILENAME_URL=$(urlencode "$FILENAME")
    URL="https://${CF_DOMAIN}/${FILENAME_URL}?token=${CF_TOKEN}&b64=${BASE64_TEXT}"

    # 使用 curl 发送请求
    curl -s "$URL" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "文件 $FILENAME 的数据更新失败。"
    else
        echo "已处理文件 $FILENAME 的数据更新，继续处理下一个文件..."
    fi
done

echo "所有文件的数据更新完成。"
