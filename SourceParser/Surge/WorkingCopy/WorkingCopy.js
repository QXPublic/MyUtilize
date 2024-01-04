/*
Working Copy使用方法：

利用 GitHub Education 解锁 Working Copy

启用此脚本后再 Safari 打开 https://workingcopy.app/education/ 点击「tap here to access all pro features.」中的 here 跳转到 Working Copy，登录自己的 GitHub 账号即可解锁

[rewrite_local]
^https?:\/\/education\.github\.com\/api\/user url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/SourceParser/Surge/WorkingCopy/WorkingCopy.js

[MitM]
hostname = education.github.com

 */

$done({body: '{"student": true}'})
