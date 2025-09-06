#!/bin/bash

# ==============================================================================
# reality_check.sh - 检测Reality协议伪装域名的延迟并排序
# 更新说明: 加入更多针对德国服务器的低延迟域名候选
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
BLUE='\033[0;34m' # 新增蓝色，用于提示信息
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

    # 新增来自搜索推荐的部分域名:cite[1]
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
echo -e "${BLUE}信息: 当前脚本包含 ${#DOMAINS[@]} 个待测试域名。${NC}"
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
            # 格式化输出，%-40s表示左对齐，宽度40（因有些新域名较长）
            printf "  %-40s -> ${GREEN}%.3f ms${NC}\n" "$DOMAIN" "$AVG_LATENCY"
            # 将结果存入临时文件，格式为 "延迟 域名" 以便排序
            echo "$AVG_LATENCY $DOMAIN" >> "$RESULTS_FILE"
        else
            printf "  %-40s -> ${RED}无法解析延迟${NC}\n" "$DOMAIN"
        fi
    else
        printf "  %-40s -> ${RED}超时或无法访问${NC}\n" "$DOMAIN"
    fi
done

echo "=================================================="
echo -e "${YELLOW}测试完成，延迟最低的前 10 个域名：${NC}" # 改为显示前10，便于选择
echo "--------------------------------------------------"

# 检查结果文件是否为空
if [ -s "$RESULTS_FILE" ]; then
    # 对结果进行数字排序，并显示前10名
    # -n 表示按数值排序, -k1 表示按第一列（延迟）排序
    sort -n -k1 "$RESULTS_FILE" | head -n 10 | while read line; do
        LATENCY=$(echo $line | awk '{print $1}')
        DOMAIN=$(echo $line | awk '{print $2}')
        printf "  ${GREEN}%-10.3f ms${NC}\t%s\n" "$LATENCY" "$DOMAIN"
    done
else
    echo -e "${RED}没有检测到任何可用的域名。${NC}"
fi

echo "--------------------------------------------------"
echo -e "${BLUE}提示: 延迟仅供参考，选择域名时还需考虑其是否支持 TLS 1.3 和 HTTP/2。${NC}"
