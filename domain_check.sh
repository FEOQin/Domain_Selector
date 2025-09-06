#!/bin/bash

# ==============================================================================
# reality_check.sh - 检测Reality协议伪装域名的延迟并检查TLS 1.3和HTTP/2支持
# 更新说明: 加入TLS 1.3和HTTP/2支持检查功能，并优化结果筛选逻辑
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
    "www.eu.cloudflare.com"  # Cloudflare欧洲特定域名

    # Fastly 相关 (另一家CDN)
    "fastly.net"
    "prod.flatpak-api.fly.dev" # 示例Fastly服务
    "edge.eu.fastly.net"       # Fastly欧洲边缘节点

    # Amazon AWS 相关 (全球CDN)
    "aws.amazon.com"
    "d1.awsstatic.com"
    "s0.awsstatic.com"
    "player.live-video.net"
    "eu-central-1.console.aws.amazon.com"  # AWS欧洲中部控制台

    # Google 相关 (全球网络)
    "google.com"
    "www.google.com"
    "gstatic.com"
    "fonts.googleapis.com"
    "fonts.gstatic.com"
    "dns.google"                           # Google DNS

    # Microsoft 相关 (Azure/CDN)
    "microsoft.com"
    "www.microsoft.com"
    "azure.com"
    "live.com"
    "cdn-eu.azureedge.net"                 # Microsoft Azure欧洲CDN

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
    "www.de.wikipedia.org"                 # 维基百科德国站点
    "de.wikipedia.org"                     # 维基百科德国站点
    "www.bbc.co.uk"                        # BBC英国站点

    # 特定欧洲或德国服务/CDN
    "hetzner.com"                          # 德国知名主机商:cite[1]:cite[6]
    "contabo.com"                          # 德国主机商:cite[10]
    "ovh.com"                              # 法国主机商，但在德国也有业务
    "digitalocean.com"
    "stackoverflow.com"
    "sstatic.net"                          # Stack Exchange CDN

    # 游戏相关 (部分在欧洲有服务器)
    "riotgames.com"
    "auth.riotgames.com"
    "lol.secure.dyn.riotcdn.net"
    "europe.api.riotgames.com"             # Riot Games欧洲API服务器
    "prod.eu.lol.riotgames.com"            # 英雄联盟欧洲服务器

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

    # 新增更多欧洲/德国优化域名
    "www.eu.cloudflare.com"                # Cloudflare欧洲节点
    "edge.eu.fastly.net"                   # Fastly欧洲边缘节点
    "europe.cdn.ampproject.org"            # AMP项目欧洲CDN
    "cdn-eu.azureedge.net"                 # Microsoft Azure欧洲CDN
    "www.de.wikipedia.org"                 # 维基百科德国站点 (流量大，本地可能有缓存)
    "www.spotify.com"                      # Spotify全球服务 (在欧洲有大量服务器)
    "de.wikipedia.org"                     # 维基百科德国站点
    "www.bbc.co.uk"                        # BBC英国站点 (地理位置相对较近)
    "europe-west1.cloudfunctions.net"      # Google Cloud欧洲区域
    "aws-eu-central-1.console.aws.amazon.com" # AWS欧洲（法兰克福）控制台
    "status.eu-central-1.console.aws.amazon.com" # AWS欧洲（法兰克福）状态页
    "europe.api.riotgames.com"             # Riot Games欧洲API服务器
    "prod.eu.lol.riotgames.com"            # 英雄联盟欧洲服务器
    "level3.ssl.blizzard.com"              # 暴雪游戏欧洲服务器
    "dns.google"                           # Google DNS (anycast节点，可能会解析到较近的服务器)
    "dns10.quad9.net"                      # Quad9 DNS欧洲节点
    "de.ntp.org"                           # NTP欧洲服务器池 (虽然用途不同，但通常是低延迟的关键基础设施)
    "nl.ntp.org"                           # NTP荷兰服务器
    "fr.ntp.org"                           # NTP法国服务器
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
ELIGIBLE_RESULTS_FILE=$(mktemp)
trap 'rm -f "$RESULTS_FILE" "$ELIGIBLE_RESULTS_FILE"' EXIT

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
            
            # 获取TLS 1.3和HTTP/2的检查结果状态
            check_tls13 "$DOMAIN" >/dev/null 2>&1
            TLS13_STATUS=$?
            check_h2 "$DOMAIN" >/dev/null 2>&1
            H2_STATUS=$?
            
            # 格式化输出
            printf "  %-40s -> ${GREEN}%.3f ms${NC} %s %s\n" "$DOMAIN" "$AVG_LATENCY" "$TLS13_SUPPORT" "$H2_SUPPORT"
            
            # 将结果存入临时文件，格式为 "延迟 域名 TLS1.3状态 H2状态" 以便排序和筛选
            echo "$AVG_LATENCY $DOMAIN $TLS13_STATUS $H2_STATUS" >> "$RESULTS_FILE"
            
            # 如果同时支持TLS 1.3和HTTP/2，则添加到符合条件的文件
            if [ $TLS13_STATUS -eq 0 ] && [ $H2_STATUS -eq 0 ]; then
                echo "$AVG_LATENCY $DOMAIN" >> "$ELIGIBLE_RESULTS_FILE"
            fi
        else
            printf "  %-40s -> ${RED}无法解析延迟${NC}\n" "$DOMAIN"
        fi
    else
        printf "  %-40s -> ${RED}超时或无法访问${NC}\n" "$DOMAIN"
    fi
done

echo
echo "==================================================================================================="

# 检查符合条件的域名数量
ELIGIBLE_COUNT=$(wc -l < "$ELIGIBLE_RESULTS_FILE")
if [ $ELIGIBLE_COUNT -eq 0 ]; then
    echo -e "${RED}没有找到同时支持TLS 1.3和HTTP/2的域名。${NC}"
    echo "---------------------------------------------------------------------------------------------------"
    exit 1
fi

echo -e "${YELLOW}测试完成，从 $ELIGIBLE_COUNT 个同时支持TLS 1.3和HTTP/2的域名中选出延迟最低的前 10 个：${NC}"
echo "---------------------------------------------------------------------------------------------------"

# 对符合条件的域名进行排序，并显示前10名
sort -n -k1 "$ELIGIBLE_RESULTS_FILE" | head -n 10 | while read line; do
    LATENCY=$(echo $line | awk '{print $1}')
    DOMAIN=$(echo $line | awk '{print $2}')
    printf "  ${GREEN}%-10.3f ms${NC}\t%s\n" "$LATENCY" "$DOMAIN"
done

echo "---------------------------------------------------------------------------------------------------"
echo -e "${BLUE}提示: 已筛选出同时支持TLS 1.3和HTTP/2的域名，这些是最适合用于Reality协议的伪装域名。${NC}"
