#!/bin/bash
# 切换到ip443目录（根据实际情况调整路径，如果相对路径不行可使用绝对路径）
cd ip443 || { echo "无法切换到ip443目录，脚本退出。" >&2; exit 1; }

# 自定义URL编码函数，用于对文件名等进行URL编码（解决bash没有内置urlencode函数的问题）
urlencode() {
    local string="${1}"
    local encoded=""
    local pos c o

    [ -z "$string" ] && return

    while [ $pos -lt ${#string} ]; do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9]) o="$c" ;;
            *) o=$(printf '%%%02X' "'$c") ;;
        esac
        encoded+="$o"
        pos=$((pos + 1))
    done

    echo "$encoded"
}

# 从环境变量中获取 CF_DOMAIN 和 CF_TOKEN
CF_DOMAIN="${CF_DOMAIN}"
CF_TOKEN="${CF_TOKEN}"

# 获取传入的所有文件名参数（假设在GitHub Actions中会传入多个文件名作为参数）
files=("$@")

# 循环处理每个文件
for FILENAME in "${files[@]}"; do
    # 判断文件是否存在，如果不存在则跳过该文件的处理
    if [! -f "$FILENAME" ]; then
        echo "文件 $FILENAME 不存在，跳过该文件的处理。"
        continue
    fi

    # 逐行读取文件前65行内容进行Base64编码，避免大文件时内存占用过多问题
    BASE64_TEXT=""
    line_count=0
    while read -r line && [ $line_count -lt 65 ]; do
        BASE64_TEXT+=$(echo "$line" | base64)
        line_count=$((line_count + 1))
    done < "$FILENAME"
    BASE64_TEXT=$(echo -n "$BASE64_TEXT" | base64 -w 0)

    FILENAME_URL=$(urlencode "$FILENAME")
    URL="https://${CF_DOMAIN}/${FILENAME_URL}?token=${CF_TOKEN}&b64=${BASE64_TEXT}"

    # 使用curl发送请求，并根据返回状态码进行更详细的错误处理
    curl -s "$URL" &> /dev/null
    response_code=$?
    if [ $response_code -eq 0 ]; then
        echo "已处理文件 $FILENAME 的数据更新，继续处理下一个文件..."
    elif [ $response_code -eq 404 ]; then
        echo "文件 $FILENAME 对应的资源未找到，数据更新失败。"
    elif [ $response_code -eq 401 ]; then
        echo "认证失败，无法更新文件 $FILENAME 的数据，请检查 CF_TOKEN 是否正确。"
    else
        echo "文件 $FILENAME 的数据更新出现未知错误，错误码：$response_code"
    fi
done

echo "所有文件的数据更新完成。"
