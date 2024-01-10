/*

[rewrite_local]

^https?:\/\/api\.chataiassistant\.com\/api(\/ai\/get-active-subscription-data|\/users\/login-register-user) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/ChatAI.js

[mitm]
hostname = api.chataiassistant.com
*/
var body = $response.body;
var url = $request.url;
//会员
if (url.indexOf('ai/get-active-subscription-data') != -1) {
    var obj = JSON.parse(body);
    obj.data = {
    "credit_used" : 0,
    "can_use" : 1,
    "free_type" : 3,
    "ai_subscription_end_time" : "4100731932000",
    "ai_subscription_active" : 1,
    "free_expired_time" : ""
  };
    body = JSON.stringify(obj);
} else if (url.indexOf('users/login-register-user') != -1) {
    var obj = JSON.parse(body);
    obj.data.ai_subscription_active = 1;
    obj.data.ai_subscription_end_time = "4100731932000";
    obj.data.free_type = 3 ;
    body = JSON.stringify(obj);

}
$done({ body });


