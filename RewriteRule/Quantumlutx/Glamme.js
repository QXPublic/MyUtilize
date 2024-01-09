/*

[rewrite_local]

^https?:\/\/glammeai-app-service\.pixelcell\.com\/api\/v3\/(user\/initialise|vip\/vip_card) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/RewriteRule/Quantumlutx/Glamme.js

[mitm]
hostname = glammeai-app-service.pixelcell.com
*/
var body = $response.body;
var url = $request.url;
//会员
if (url.indexOf('user/initialise') != -1) {
    var obj = JSON.parse(body);
    obj.response.user.vip = true;
    body = JSON.stringify(obj);
} else if (url.indexOf('vip/vip_card') != -1) {
    var obj = JSON.parse(body);
    obj = {
  "response" : {
    "vip_info" : {
      "is_vip" : true,
      "is_auto_renew" : true,
      "start_at" : 1704806188.7748761,
      "is_trial" : false,
      "is_vip_in_history" : false,
      "sku" : "",
      "expired_at" : 4100731932.7748761,
      "vip_level" : 1,
      "user_id" : 10173151
    }
  },
  "result" : 1,
  "uri" : "\/api\/v3\/vip\/vip_card",
  "component" : "vip",
  "message" : "success",
  "timestamp" : 1704807067
};

}
$done({ body });
