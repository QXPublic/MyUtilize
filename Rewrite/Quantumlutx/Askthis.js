/*

[rewrite_local]

^https?:\/\/askthisai-app-service\.pixelcell\.com\/api\/v3\/(user\/initialise|vip\/vip_card) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Askthis.js

[mitm]
hostname = askthisai-app-service.pixelcell.com
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
    obj.response.vip_info.is_vip = true;
    obj.response.vip_info.is_auto_renew = true;
    obj.response.vip_info.start_at = 1704806188.7748761;
    obj.response.vip_info.expired_at = 4100731932.7748761;
    obj.response.vip_info.vip_level = 1;
    body = JSON.stringify(obj);

}
$done({ body });
