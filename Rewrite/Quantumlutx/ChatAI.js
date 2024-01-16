/*

[rewrite_local]

^https?:\/\/api\.chataiassistant\.com\/api\/users\/login-register-user url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/ChatAI.js

[mitm]
hostname = api.chataiassistant.com
*/
var body = $response.body;
//var url = $request.url;
//会员
  var obj = JSON.parse(body);
    obj.data.ai_subscription_active = 1;
    obj.data.ai_subscription_end_time = "4100731932000";
    obj.data.free_type = 3 ;
    body = JSON.stringify(obj);
$done({ body });


