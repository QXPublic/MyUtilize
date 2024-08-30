#!/bin/bash

# 更新和升级系统
sudo apt update && sudo apt upgrade -y

# 如果没有安装，安装 Python3 和 pip
sudo apt install -y python3 python3-pip

# 安装 psutil 包
pip3 install psutil --break-system-packages

# 创建 Python 脚本
cat << EOF | sudo tee /root/servertraffic.py
#!/usr/bin/env python3

import http.server
import socketserver
import json
import time
import psutil

port = 7122

class RequestHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

        time.sleep(1)

        cpu_usage = psutil.cpu_percent(interval=1)
        mem_usage = psutil.virtual_memory().percent
        bytes_sent = psutil.net_io_counters().bytes_sent
        bytes_recv = psutil.net_io_counters().bytes_recv
        bytes_total = bytes_sent + bytes_recv

        utc_timestamp = int(time.time())
        uptime = int(time.time() - psutil.boot_time())

        last_time = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())

        response_dict = {
            "utc_timestamp": utc_timestamp,
            "uptime": uptime,
            "cpu_usage": cpu_usage,
            "mem_usage": mem_usage,
            "bytes_sent": str(bytes_sent),
            "bytes_recv": str(bytes_recv),
            "bytes_total": str(bytes_total),
            "last_time": last_time
        }

        response_json = json.dumps(response_dict).encode('utf-8')
        self.wfile.write(response_json)

with socketserver.ThreadingTCPServer(("", port), RequestHandler, bind_and_activate=False) as httpd:
    try:
        print(f"Serving at port {port}")
        httpd.allow_reuse_address = True
        httpd.server_bind()
        httpd.server_activate()
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("KeyboardInterrupt is captured, program exited")
EOF

# 使 Python 脚本可执行
sudo chmod +x /root/servertraffic.py

# 创建 systemd 服务文件
cat << EOF | sudo tee /etc/systemd/system/servertraffic.service
[Unit]
Description=Server Traffic Monitor

[Service]
Type=simple
WorkingDirectory=/root/
User=root
ExecStart=/usr/bin/python3 /root/servertraffic.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd，启用并启动服务器流量监控服务
sudo systemctl daemon-reload
sudo systemctl enable servertraffic.service
sudo systemctl start servertraffic.service

# 检查服务状态
sudo systemctl status servertraffic.service

