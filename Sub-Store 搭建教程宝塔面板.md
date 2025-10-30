1. 安装 Node.js 管理器

宝塔面板 > 软件商店 > Node项目管理器 > 安装，安装完后点击添加项目并选择 LTS 版本：v20.18.0。

2. 准备项目文件夹

宝塔文件管理 > wwwroot 目录下新建文件夹 SubStore

3. 创建 package.json

进入 SubStore 文件夹，创建 package.json 文件：
```
{
  "name": "sub-store",
  "version": "1.0.0",
  "description": "Sub-Store project",
  "main": "sub-store.bundle.js",
  "scripts": {
    "start": "SUB_STORE_FRONTEND_BACKEND_PATH=/xxxxxxxxxxxxxxxxxxxx SUB_STORE_BACKEND_CRON='0 0 * * *' SUB_STORE_FRONTEND_PATH=/www/wwwroot/SubStore/dist SUB_STORE_FRONTEND_HOST=0.0.0.0 SUB_STORE_FRONTEND_PORT=3321 SUB_STORE_DATA_BASE_PATH=/www/wwwroot/SubStore SUB_STORE_BACKEND_API_HOST=127.0.0.1 SUB_STORE_BACKEND_API_PORT=3300 /www/server/nodejs/v20.18.0/bin/node /www/wwwroot/SubStore/sub-store.bundle.js"
  }
}
```
4. 下载前后端代码

在当前目录使用 URL 链接下载功能：
```
https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js
https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip
```
解压 dist.zip 并重命名为 dist

5. 添加 Node 项目

宝塔 > Node项目 > 添加项目：

项目路径：/www/wwwroot/SubStore
启动端口：3333
Node版本：选择 v20.18.0
启用随系统启动 
6. 配置反向代理 & SSL

宝塔 > 网站 > 添加站点（填入域名）> SSL：粘贴证书 & 密钥 > 开启强制 HTTPS

反代设置：目标 URL 填写：http://127.0.0.1:3333

访问地址：https://sub.yourdomain.com/?api=https://sub.yourdomain.com/xxxxxxxxxxxxxxxxxxxx



