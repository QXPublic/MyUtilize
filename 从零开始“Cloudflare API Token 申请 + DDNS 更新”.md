从零开始“Cloudflare API Token 申请 + DDNS 更新”详细步骤，跟着做就能跑起来

项目需求： AWS lightsail 重启 ip 更改 同步 cf dns 以及tg通知

# 一、前提检查

- 域名已接入 Cloudflare（能在 Cloudflare 仪表盘看到你的域名）。
- 你的 VPS 可以访问外网（curl/jq 可用）。

建议先安装依赖：
```bash
sudo apt-get update && sudo apt-get install -y curl jq
# 或 CentOS/RHEL:
# sudo yum install -y curl jq
```

# 二、在 Cloudflare 创建最小权限 API Token

1. 登录 Cloudflare 仪表盘：Dashboard → 右上头像 → My Profile → API Tokens。
2. 点击 “Create Token”，选择模板 “Edit zone DNS”（官方模板，最小权限）。
3. Permissions（权限）保持为：
   - Zone → DNS → Edit
4. Zone Resources（作用范围）设置为：
   - Include → Specific zone → 选择你的域名
5. 可选安全项：
   - Token IP Address Filtering：如你的请求源 IP 固定，可填写允许的 IP，进一步加固。（VPS IP 若经常变动，不建议勾）
6. 点击 Create Token，复制生成的 Token（只会显示一次）。妥善保存。

注意：
- 强烈不建议使用 Global API Key（全局密钥），权限过大且安全风险高。
- Token 泄露后他人可改你域名 DNS，务必当密码管。

# 三、获取 Zone ID（区域 ID）

方式一：仪表盘查看  
进入你的域名 → Overview 页面右侧 “API” 区块即可看到 Zone ID。

方式二：API 查询
```bash
CF_TOKEN="粘贴你的Token"
ZONE_NAME="example.com"

curl -s -H "Authorization: Bearer &#36;CF_TOKEN" \
     "https://api.cloudflare.com/client/v4/zones?name=&#36;ZONE_NAME" \
| jq -r '.result[0].id'
```
把输出复制出来作为 `ZONE_ID`。

# 四、用 API 管理 DNS 记录（A/AAAA）

- 查询记录是否存在：
```bash
CF_TOKEN="你的Token"
ZONE_ID="你的ZoneID"
RECORD_NAME="app.example.com"

curl -s -H "Authorization: Bearer &#36;CF_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/&#36;ZONE_ID/dns_records?type=A&name=&#36;RECORD_NAME" \
| jq .
```

- 创建 A 记录（不存在时）：
```bash
curl -sX POST -H "Authorization: Bearer &#36;CF_TOKEN" -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/&#36;ZONE_ID/dns_records" \
  --data '{
    "type":"A",
    "name":"app.example.com",
    "content":"1.2.3.4",
    "ttl":120,
    "proxied":true
  }' | jq .
```

- 更新 A 记录（已存在时需要 REC_ID）：
```bash
REC_ID="现有记录的id"
curl -sX PUT -H "Authorization: Bearer &#36;CF_TOKEN" -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/&#36;ZONE_ID/dns_records/&#36;REC_ID" \
  --data '{
    "type":"A",
    "name":"app.example.com",
    "content":"1.2.3.4",
    "ttl":120,
    "proxied":true
  }' | jq .
```

- AAAA 记录把 `"type":"A"` 改为 `"type":"AAAA"`，`content` 放 IPv6 即可。

小提示：
- `ttl: 1` 表示 “Auto”。若走小云朵（proxied:true），客户端实际拿到的是 Cloudflare 的 IP，即使 TTL 比较高也没关系。
- 若你要直连非 HTTP 服务，通常应设 `proxied:false`（否则需要 Cloudflare Spectrum，付费）。

# 五、DDNS 一键脚本（A/AAAA 自动创建/更新）

保存为 `/usr/local/bin/cf-ddns.sh`，给执行权限：`chmod +x /usr/local/bin/cf-ddns.sh`

```
#!/usr/bin/env bash
#
# Cloudflare DDNS Script for AWS EC2 with Telegram Notifications
#
set -euo pipefail

# ---==============[ 必填配置 ]==============---

# Cloudflare API 令牌 (Zone:DNS:Edit 权限)
CF_TOKEN="Cloudflare API"

# 你的域名 Zone ID
ZONE_ID="Zone ID"

# 要更新的完整 DNS 记录名称 (例如: sub.example.com)
RECORD_NAME="sub.example.com"

# 是否开启 Cloudflare 代理 (小云朵) true/false
PROXIED=false

# TTL (Time To Live), 1 为自动
TTL=120

# ---=========[ Telegram 通知配置 ]=========---

# 是否启用 Telegram 通知 (true/false)
TG_ENABLED=true

# 你的 Telegram Bot 令牌
BOT_TOKEN="YOUR_BOT_TOKEN" # <--- 替换成你的 Bot Token

# 你的 Telegram Chat ID
CHAT_ID="YOUR_CHAT_ID" # <--- 替换成你的 Chat ID

# ---==============[ 脚本主体 ]==============---

# 设置日志文件路径
LOG_FILE="/var/log/cloudflare_ddns.log"

# 日志记录函数
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 从 AWS 元数据服务获取公网 IPv4 (最可靠的方式)
fetch_ipv4() {
  curl -fsS http://169.254.169.254/latest/meta-data/public-ipv4
}

# 发送 Telegram 通知
send_tg_notification() {
  local message="$1"
  if [ "$TG_ENABLED" = true ]; then
    # 使用 curl 向 Telegram API 发送 POST 请求
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      -d "text=${message}" \
      -d "parse_mode=Markdown" > /dev/null # 丢弃输出结果
    log "[TG] 通知已发送。"
  fi
}

log "====== 开始执行 DDNS 更新任务 ======"

# 1. 获取新的公网 IP
new_ip=$(fetch_ipv4)
if [ -z "$new_ip" ]; then
  log "[错误] 获取公网 IP 失败！请检查网络或元数据服务。"
  exit 1
fi
log "[A] 获取到新的公网 IP: $new_ip"

# 2. 从 Cloudflare 获取旧的 IP
api_url="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${RECORD_NAME}"
headers=(-H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json")

record_data=$(curl -sS "${headers[@]}" "$api_url")

# 检查 API 调用是否成功
if ! echo "$record_data" | jq -e '.success' > /dev/null; then
  error_msg=$(echo "$record_data" | jq -r '.errors[0].message')
  log "[错误] 查询 DNS 记录失败: $error_msg"
  send_tg_notification "🚨 **DDNS 更新失败** 🚨%0A%0A域名: \`$RECORD_NAME\`%0A原因: 查询 DNS 记录失败: $error_msg"
  exit 1
fi

# 3. 比较 IP 并决定是否更新
record_count=$(echo "$record_data" | jq '.result | length')

if [ "$record_count" -eq 0 ]; then
  log "[A] DNS 记录不存在, 准备创建..."
  # 创建新记录的逻辑 (这里简化, 假设记录已存在, 如有需要可补充 create_record 函数)
  log "[错误] 记录不存在的功能尚未实现, 请先在 Cloudflare 手动创建一条 A 记录。"
  send_tg_notification "⚠️ **DDNS 更新警告** ⚠️%0A%0A域名: \`$RECORD_NAME\`%0A原因: DNS 记录不存在，请先手动创建。"
  exit 1
else
  old_ip=$(echo "$record_data" | jq -r '.result[0].content')
  record_id=$(echo "$record_data" | jq -r '.result[0].id')
  log "[A] 获取到旧的 DNS 记录 IP: $old_ip"

  if [ "$old_ip" == "$new_ip" ]; then
    log "[A] 当前 IP ($old_ip) 与新 IP ($new_ip) 相同, 无需更新。"
  else
    log "[A] IP 已变更, 从 $old_ip 更新到 $new_ip. 正在执行更新..."
    
    update_url="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${record_id}"
    update_data=$(jq -n \
      --arg type "A" \
      --arg name "$RECORD_NAME" \
      --arg content "$new_ip" \
      --argjson ttl "$TTL" \
      --argjson proxied "$PROXIED" \
      '{type: $type, name: $name, content: $content, ttl: $ttl, proxied: $proxied}')

    update_response=$(curl -sS -X PUT "${headers[@]}" "$update_url" --data "$update_data")

    if echo "$update_response" | jq -e '.success' > /dev/null; then
      log "[成功] DNS 记录已成功更新为: $new_ip"
      # 构建并发送成功通知
      tg_message="✅ **DDNS 更新成功** ✅%0A%0A域名: \`$RECORD_NAME\`%0A旧 IP: \`$old_ip\`%0A新 IP: \`$new_ip\`"
      send_tg_notification "$tg_message"
    else
      error_msg=$(echo "$update_response" | jq -r '.errors[0].message')
      log "[错误] DNS 记录更新失败: $error_msg"
      # 构建并发送失败通知
      tg_message="🚨 **DDNS 更新失败** 🚨%0A%0A域名: \`$RECORD_NAME\`%0A尝试更新到: \`$new_ip\`%0A原因: $error_msg"
      send_tg_notification "$tg_message"
    fi
  fi
fi

log "====== DDNS 更新任务执行完毕 ======"

```

可先手动跑一次验证：
```bash
bash /usr/local/bin/cf-ddns.sh
```

# 六、ip更换后自动更改

创建一个新的服务文件：
```
sudo vim /etc/systemd/system/cloudflare-ddns.service
```
将以下内容粘贴到文件中：
```
[Unit]
Description=Cloudflare DDNS Updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cf-ddns.sh

[Install]
WantedBy=multi-user.target

```
重新加载 systemd 配置：sudo systemctl daemon-reload 
设置服务开机自启：sudo systemctl enable cloudflare-ddns.service
立即手动运行:sudo systemctl start cloudflare-ddns.service


- 常见问题：
  - 403/Authentication error：检查 Token 是否是 “API Token”（不是 Global API Key），且权限与 Zone 范围正确。
  - 更新无效但返回 success：多数是你改了非代理记录的 TTL/DNS 缓存，等几分钟或降低 TTL；若是 proxied:true，变更通常几乎即时生效。
  - IPv6 获取不到：你的 VPS/网络可能未启用 IPv6，删除脚本中 AAAA 那行或为 IPv6 单独部署。


