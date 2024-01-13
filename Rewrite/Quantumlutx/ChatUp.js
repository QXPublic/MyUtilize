/*

[rewrite_local]

^https?:\/\/us-central1-mobile-gpt-prod\.cloudfunctions\.net\/getUserInfoV2 url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/ChatUp.js

[mitm]
hostname = us-central1-mobile-gpt-prod.cloudfunctions.net
*/
var body = $response.body;
//var url = $request.url;

//会员
    var obj = JSON.parse(body);
   obj.result.userTier = "Premium";
   obj.result.maxDailyCap = 300;
   obj.result.dailyCap = 300;
   body = JSON.stringify(obj);

   
$done({ body });