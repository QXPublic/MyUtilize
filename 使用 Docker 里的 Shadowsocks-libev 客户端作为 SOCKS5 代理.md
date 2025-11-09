使用 Docker 里的 Shadowsocks-libev 客户端作为 SOCKS5 代理

1、创建config.json文件进行编辑
```
vim /etc/shadowsocks-client/config.json
```
2、把下面的内容粘贴到刚刚创建的config.json,填入对应的信息
```
{
  "server": "xxxx",
  "server_port": xxxx,
  "local_address": "127.0.0.1",
  "local_port": 1080,
  "password": "xxxx",
  "timeout": 300,
  "method": "xxxx",
  "fast_open": false
}
```
3、创建并启动容器
```
docker run -d --name ss-client -p 1080:1080/tcp -p 1080:1080/udp -v /etc/shadowsocks-client:/etc/shadowsocks-libev --restart=always shadowsocks/shadowsocks-libev
```
4、测试是否成功
```
curl --socks5 127.0.0.1:1080 https://ipinfo.io/ip
```
