# MyUtilize_Public
-x- Everything is collected from public online sources or some by mine. I can not confirm its right and useful.All script-rules belong its authors'. Best Wish for you ervrything!

#一键搭建VPS流量监控----------------------------------------------------------------------------------------------------------------------

wget -N --no-check-certificate https://raw.githubusercontent.com/QXPublic/MyUtilize/main/SourceParser/setup_traffic.sh && chmod +x setup_traffic.sh && ./setup_traffic.sh

Surge模块安装

将下面内容复制到本地模块中：
#!name=CatVPS
#!desc=监控VPS流量信息和处理器、内存占用情况
#!author= 面板和脚本部分@wuhu_zzz VPS端部分 @ATRI0828 由 @整点猫咪 进行整理
#!howto=将模块内容复制到本地后根据自己VPS IP地址及端口修改 http://127.0.0.1:49155/traffic 部分进行使用ddl=后面接你的VPS到期时间，total=输入你的VPS每月流量数目

[Panel]
Cat VPS = script-name=CatVPS

[Script]
CatVPS = type=generic,script-path=https://raw.githubusercontent.com/QXPublic/MyUtilize/main/SourceParser/Surge/CatVPS/CatVPS.js, argument = url=http://127.0.0.1:49155/traffic&title=Cat VPS&icon=bolt.horizontal.icloud.fill&low=#06D6A0&mid=#FFD166&high=#EF476F&ddl=2100-01-01&total=10TB

#####----------------------------------------------------------------------------------------------------------------------
