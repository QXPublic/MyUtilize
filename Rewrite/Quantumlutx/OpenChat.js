
/*

[rewrite_local]

^https?:\/\/api\.qonversion\.io\/v1\/user\/init url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/OpenChat.js

[mitm]
hostname = api.qonversion.io
*/
var body = $response.body;
//var url = $request.url;
/*
let userProducts = {
  "user_products" : []
};
let Permissions = {
  "permissions" : []
};
*/



//会员
    var obj = JSON.parse(body);
    delete obj.data[("user_products")];
    delete obj.data[("permissions")];
    const data1 = [
      {
        "id" : "chat.yearly.null.v1.0423",
        "type" : 0,
        "store_id" : "chat.yearly.null.v1.0423",
        "duration" : 0
      }
    ];
    const data11 = [
      {
        "id" : "pro",
        "trial_start_timestamp" : 1705131631,
        "active" : 1,
        "started_timestamp" : 1705131631,
        "grant_type" : "purchase",
        "associated_product" : "chat.yearly.null.v1.0423",
        "source" : "appstore",
        "renews_count" : 0,
        "store_transactions" : [
          {
            "ownership_type" : "owner",
            "transaction_id" : "570001417499095",
            "environment" : "production",
            "transaction_timestamp" : 1705131631,
            "expiration_timestamp" : 4071977134,
            "original_transaction_id" : "570001417499095",
            "type" : "yearly"
          }
        ],
        "current_period_type" : "yearly",
        "expiration_timestamp" : 4071977134,
        "renew_state" : 1
      }
    ];
    obj.data[("user_products")] =(data1) ;
    obj.data[("permissions")] = (data11);
    
    body = JSON.stringify(obj);

$done({ body });
