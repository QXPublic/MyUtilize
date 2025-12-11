目的：安装 3xui面板并定时重启以避免长时间运行可能导致的内存泄露等问题，保持使用流畅
3xui面板搭建官方一键脚本:

 1、登录 vps 执行改命令，按指示操作即可
```
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```
2、定时重启 3xui：

找到 x-ui 命令的绝对路径
```
which x-ui
```
编辑 Crontab 文件
第一次运行这个命令，系统可能会让您选择一个默认的文本编辑器（如 nano 或 vim）
```
crontab -e
```
添加定时任务规则

每2小时重启一次
在 crontab 文件中添加下面这行（假设 x-ui 的路径是 /usr/bin/x-ui）：
```
0 */2 * * * /usr/bin/x-ui restart

```

验证是否添加成功
```
crontab -l
```


