
/*
[rewrite_local]
^https?:\/\/api\.chatapp\.dev\/users\/\w+\/\?hash=\w+&uid=\w+&v=[1-9]\.[0-9] url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/CHAT.js 

[mitm]
hostname = api.chatapp.dev

*/

var obj = JSON.parse($response.body);
    obj.user.subscription_valid = true;
    obj.user.is_plus = true;
    obj.user.valid_until = "4072603667";

$done({body : JSON.stringify(obj)});