🛠️ 脚本特点说明
面板交互：运行 ./anytls.sh 即可随时呼出菜单，进行重启、查看配置或修改密码。
服务守护：使用 systemd 托管，服务器重启后 AnyTLS 会自动启动。
自动更新：脚本自动抓取 GitHub 上 anytls-go 项目的最新 Release 版本进行安装。

```
wget -N --no-check-certificate "https://raw.githubusercontent.com/QXPublic/MyUtilize/refs/heads/main/VPS/anytls.sh" && chmod +x anytls.sh && ./anytls.sh

```
