/*

[rewrite_local]

^https?:\/\/api\.gchatapp\.net\/api\/(init|v1\/premium-users\/\w+-\w+-\w+-\w+-\w+\/check) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Gchat.js

[mitm]
hostname = api.gchatapp.net
*/
var body = $response.body;
var url = $request.url;
//会员
if (url.indexOf('init') != -1) {
    var obj = JSON.parse(body);
    obj.default_package_name = "yearly" ;
    body = JSON.stringify(obj);
} else if (url.indexOf('v1/premium-users/\w+-\w+-\w+-\w+-\w+/check') != -1) {
    var obj = JSON.parse(body);
    obj.is_trial = false;
    obj.expired_date = "2099-01-15 13:13:31";
    obj.auto_renew_status = true ;
    body = JSON.stringify(obj);

}
$done({ body });
