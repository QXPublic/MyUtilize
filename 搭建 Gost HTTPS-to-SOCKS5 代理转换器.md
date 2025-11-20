目的：将一个需要用户名密码验证的 HTTPS 代理，转换为一个在 VPS 本地运行的、无需验证的 SOCKS5 代理。

1、安装 Docker 和 Docker Compose
1. 更新系统软件包列表：
```
apt update
```
2. 安装 Docker：
我们使用官方提供的一键安装脚本，这是最简单快捷的方式。
```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
3. 安装 Docker Compose：
Docker Compose 让我们通过一个简单的配置文件来管理 Docker 应用。
```
apt install docker-compose -y
```
4. 验证安装：
执行以下两个命令，如果都输出了版本号而不是错误信息，就代表 Docker 和 Docker Compose 都已成功安装！
```
docker --version
docker-compose --version
```
2、创建并配置 Gost 服务
1. 创建一个专门存放配置的文件夹：
```
mkdir gost-proxy
cd gost-proxy
```
2. 创建 docker-compose.yml 配置文件：
```
vim docker-compose.yml
```
4. 粘贴并修改配置内容：
执行上面的命令后，会打开一个空的编辑器界面。请完整复制下面的所有内容，然后粘贴到编辑器里。
docker-compose.yml文件里的内容：
```
version: '3.8'

services:
  https-to-socks5:
    image: ginuerzh/gost
    container_name: https-to-socks5
    restart: always
    # 映射本地 1088 端口 (仅允许本机访问，更安全)
    ports:
      - "127.0.0.1:1088:1088"
    
    environment:
      # --- ✅ 配置区域 ---
      - HTTPS_PROXY_HOST=xxxx
      - HTTPS_PROXY_PORT=xxxxx
      # 用户名 (这里必须填 URL 编码后的版本: &->%26, @->%40)
      - HTTPS_PROXY_USER=xxxxx
      - HTTPS_PROXY_PASS=xxxxx
      # ------------------

    # 覆盖默认入口点，使用 sh 来解析环境变量
    entrypoint: ["/bin/sh", "-c"]
    
    # ❗变量前使用了 $$，这是为了告诉 Docker "去容器里找这个变量，不要在宿主机找"
    command: 
      - "gost -L socks5://:1088 -F https://$$HTTPS_PROXY_USER:$$HTTPS_PROXY_PASS@$$HTTPS_PROXY_HOST:$$HTTPS_PROXY_PORT"


```

**启动运行都要与docker-compose.yml处于同一个文件夹下**

3、启动并测试服务
```
docker compose up -d
```
检查服务是否在运行：

```
docker ps
```

进行最终测试：
用 curl 命令，通过刚刚创建的本地 SOCKS5 代理去访问一个能显示我们出口 IP 的网站。

```
curl --socks5 127.0.0.1:1088 https://ipinfo.io
```




