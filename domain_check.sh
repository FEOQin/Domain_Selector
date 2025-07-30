#!/bin/bash

# ==============================================================================
# reality_check.sh - 检测Reality协议伪装域名的延迟并排序
#
# 使用方法:
# 1. 上传到 GitHub。
# 2. 在你的VPS上运行以下命令:
#    bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/reality_check.sh)
# ==============================================================================

# 设置颜色代码
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 待检测的域名列表
DOMAINS=(
    "gs.apple.com"
    "configuration.ls.apple.com"
    "is1-ssl.mzstatic.com"
    "xp.apple.com"
    "www.xbox.com"
    "sisu.xboxlive.com"
    "res-1.cdn.office.net"
    "office.cdn.microsoft.com"
    "d0.awsstatic.com"
    "vs.aws.amazon.com"
    "downloadmirror.intel.com"
    "intelcorp.scene7.com"
    "ds-aksb-a.akamaihd.net"
    "polyfill-fastly.io"
    "lpcdn.lpsnmedia.net"
)

echo -e "${YELLOW}开始检测以下 ${#DOMAINS[@]} 个域名的延迟...${NC}"
echo "=================================================="

# 创建一个临时文件来存储结果
RESULTS_FILE=$(mktemp)
# 确保脚本退出时删除临时文件
trap 'rm -f "$RESULTS_FILE"' EXIT

# 遍历所有域名进行检测
for DOMAIN in "${DOMAINS[@]}"; do
    # 使用ping测试延迟, -c 4 发送4个包, -W 2 等待2秒超时
    # 将标准错误重定向到/dev/null以保持输出整洁
    PING_OUTPUT=$(ping -c 4 -W 2 "$DOMAIN" 2>/dev/null)

    # 检查ping命令的退出状态
    if [ $? -eq 0 ]; then
        # 从最后一行 'rtt min/avg/max/mdev = ...' 中提取 avg
        AVG_LATENCY=$(echo "$PING_OUTPUT" | tail -1 | awk -F '/' '{print $5}')
        
        # 检查是否成功提取到延迟
        if [[ -n "$AVG_LATENCY" ]]; then
            # 格式化输出，%-30s表示左对齐，宽度30
            printf "  %-30s -> ${GREEN}%.3f ms${NC}\n" "$DOMAIN" "$AVG_LATENCY"
            # 将结果存入临时文件，格式为 "延迟 域名" 以便排序
            echo "$AVG_LATENCY $DOMAIN" >> "$RESULTS_FILE"
        else
            printf "  %-30s -> ${RED}无法解析延迟${NC}\n" "$DOMAIN"
        fi
    else
        printf "  %-30s -> ${RED}超时或无法访问${NC}\n" "$DOMAIN"
    fi
done

echo "=================================================="
echo -e "${YELLOW}测试完成，延迟最低的前 5 个域名：${NC}"
echo "--------------------------------------------------"

# 检查结果文件是否为空
if [ -s "$RESULTS_FILE" ]; then
    # 对结果进行数字排序，并显示前5名
    # -n 表示按数值排序, -k1 表示按第一列（延迟）排序
    sort -n -k1 "$RESULTS_FILE" | head -n 5 | awk '{printf "  ${GREEN}%-10.3f ms${NC}\t%s\n", $1, $2}'
else
    echo -e "${RED}没有检测到任何可用的域名。${NC}"
fi

echo "--------------------------------------------------"