#!/bin/bash

# ==============================================================================
# reality_check.sh - 检测Reality协议伪装域名的延迟并检查TLS 1.3和HTTP/2支持
# 更新说明: 加入TLS 1.3和HTTP/2支持检查功能
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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 待检测的域名列表 - 已扩展
DOMAINS=(
    # 原列表中的域名
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

    # 新增推荐域名 (主要针对欧洲/德国优化)
    # Cloudflare 相关 (大型CDN，欧洲节点多)
    "cdn-cgi.trafficmanager.net"
    "cloudflare.com"
    "one.one.one.one" # Cloudflare DNS

    # Fastly 相关 (另一家CDN)
    "fastly.net"
    "prod.flatpak-api.fly.dev" # 示例Fastly服务

    # Amazon AWS 相关 (全球CDN)
    "aws.amazon.com"
    "d1.awsstatic.com"
    "s0.awsstatic.com"
    "player.live-video.net"

    # Google 相关 (全球网络)
    "google.com"
    "www.google.com"
    "gstatic.com"
    "fonts.googleapis.com"
    "fonts.gstatic.com"

    # Microsoft 相关 (Azure/CDN)
    "microsoft.com"
    "www.microsoft.com"
    "azure.com"
    "live.com"

    # 其他大型全球服务 (通常在欧州有良好存在)
    "github.com"
    "www.github.com"
    "githubassets.com"
    "netflix.com"
    "nflxvideo.net"
    "facebook.com"
    "instagram.com"
    "whatsapp.com"
    "open.spotify.com"
    "duckduckgo.com"

    # 特定欧洲或德国服务/CDN
    "hetzner.com"
    "contabo.com"
    "ovh.com" # 法国主机商，但在德国也有业务
    "digitalocean.com"
    "stackoverflow.com"
    "sstatic.net" # Stack Exchange CDN

    # 游戏相关 (部分在欧洲有服务器)
    "riotgames.com"
    "auth.riotgames.com"
    "lol.secure.dyn.riotcdn.net"

    # 新增来自搜索推荐的部分域名
    "gateway.icloud.com"
    "itunes.apple.com"
    "swdist.apple.com"
    "swcdn.apple.com"
    "updates.cdn-apple.com"
    "download-installer.cdn.mozilla.net"
    "addons.mozilla.org"
    "images-na.ssl-images-amazon.com"
    "m.media-amazon.com"
)

# 检查TLS 1.3支持函数
check_tls13() {
    local domain=$1
    # 使用openssl检查TLS 1.3支持
    if echo | timeout 5 openssl s_client -connect "$domain:443" -tls1_3 2>/dev/null | grep -q "TLSv1.3"; then
        echo -e "${GREEN}支持TLS1.3${NC}"
        return 0
    else
        echo -e "${RED}不支持TLS1.3${NC}"
        return 1
    fi
}

# 检查HTTP/2支持函数
check_h2() {
    local domain=$1
    # 使用curl检查HTTP/2支持
    if curl -s --http2 -I "https://$domain" 2>/dev/null | grep -q "HTTP/2"; then
        echo -e "${GREEN}支持H2${NC}"
        return 0
    else
        echo -e "${RED}不支持H2${NC}"
        return 1
    fi
}

echo -e "${BLUE}信息: 当前脚本包含 ${#DOMAINS[@]} 个待测试域名。${NC}"
echo -e "${YELLOW}开始检测以下 ${#DOMAINS[@]} 个域名的延迟和协议支持...${NC}"
echo "==================================================================================================="

# 创建临时文件存储结果
RESULTS_FILE=$(mktemp)
trap 'rm -f "$RESULTS_FILE"' EXIT

# 计数器
total_domains=${#DOMAINS[@]}
current=0

# 遍历所有域名进行检测
for DOMAIN in "${DOMAINS[@]}"; do
    ((current++))
    echo -ne "${BLUE}进度: $current/$total_domains${NC}\r"
    
    # 使用ping测试延迟
    PING_OUTPUT=$(ping -c 4 -W 2 "$DOMAIN" 2>/dev/null)
    
    # 检查ping命令的退出状态
    if [ $? -eq 0 ]; then
        # 提取平均延迟
        AVG_LATENCY=$(echo "$PING_OUTPUT" | tail -1 | awk -F '/' '{print $5}')
        
        if [[ -n "$AVG_LATENCY" ]]; then
            # 检查TLS 1.3和HTTP/2支持
            TLS13_SUPPORT=$(check_tls13 "$DOMAIN")
            H2_SUPPORT=$(check_h2 "$DOMAIN")
            
            # 格式化输出
            printf "  %-40s -> ${GREEN}%.3f ms${NC} %s %s\n" "$DOMAIN" "$AVG_LATENCY" "$TLS13_SUPPORT" "$H2_SUPPORT"
            
            # 将结果存入临时文件，格式为 "延迟 域名" 以便排序
            echo "$AVG_LATENCY $DOMAIN" >> "$RESULTS_FILE"
        else
            printf "  %-40s -> ${RED}无法解析延迟${NC}\n" "$DOMAIN"
        fi
    else
        printf "  %-40s -> ${RED}超时或无法访问${NC}\n" "$DOMAIN"
    fi
done

echo
echo "==================================================================================================="
echo -e "${YELLOW}测试完成，延迟最低的前 10 个域名：${NC}"
echo "---------------------------------------------------------------------------------------------------"

# 检查结果文件是否为空
if [ -s "$RESULTS_FILE" ]; then
    # 对结果进行数字排序，并显示前10名
    sort -n -k1 "$RESULTS_FILE" | head -n 10 | while read line; do
        LATENCY=$(echo $line | awk '{print $1}')
        DOMAIN=$(echo $line | awk '{print $2}')
        printf "  ${GREEN}%-10.3f ms${NC}\t%s\n" "$LATENCY" "$DOMAIN"
    done
else
    echo -e "${RED}没有检测到任何可用的域名。${NC}"
fi

echo "---------------------------------------------------------------------------------------------------"
echo -e "${BLUE}提示: 绿色表示支持，红色表示不支持。选择域名时优先选择同时支持TLS 1.3和HTTP/2的域名。${NC}"
