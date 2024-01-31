/*
[rewrite_local]

^http:\/\/24\.199\.66\.203\:\d+\/apis\/(get-profile\?user_id=\d+|loginWithDevice) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Jarvis.js

[mitm]
hostname = 24.199.66.203
*/

var body = $response.body;
var url = $request.url;
//会员
if (url.indexOf('get-profile/?user_id=\d+') != -1) {
    var obj = JSON.parse(body);
    obj.body.subscription_type = "1";
    obj.body.account_type = 1;
    obj.body.subscription = 1;
    obj.body.expire_date = 4073587199;
    obj.body.todayWords = 15000;
    body = JSON.stringify(obj);

} else if (url.indexOf('loginWithDevice') != -1) {
    var obj = JSON.parse(body);
    obj.body.subscription_type = "1";
    obj.body.account_type = 1;
    obj.body.subscription = 1;
    obj.body.expire_date = 4073587199;
    obj.body.todayWords = 15000;
    body = JSON.stringify(obj);

}
$done({ body });
