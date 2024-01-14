
/****************************************
Chat AI
*****************************************
[rewrite_local]
^https?:\/\/api\.revenuecat\.com\/.+\/(receipts$|subscribers\/?(.*?)*$) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Chat-ai.js
^https?:\/\/api\.revenuecat\.com\/.+\/(receipts$|subscribers\/?(.*?)*$) url script-request-header https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Chat-ai.js
^https?:\/\/firestore\.googleapis\.com url reject
[mitm]
hostname = api.revenuecat.com, firestore.googleapis.com
*************************************/

const chxm1023 = {};
const chxm1024 = JSON.parse(typeof $response != "undefined" && $response.body || null);

const name = "Advanced";
const name1 = "Unlimited";
const name2 = "echo_pro";
const name21 = "2365";
const name3 = "Premium";
const name31 = "annual";
const name4 = "yearly";
const name41 = "unlimited_chats";
const name5 = "com.curiouscreatorsco.ChatLLM.pro.1year.notrial.49_99";
const name51 = "Pro";
const name6 = "com.aichatbot.askmeall.lifetime";
const name61 = "pro";
const name7 = "impact.69.99.1y";
const name71 = "full_access";

const appid = "com.palligroup.gpt3.yearlyyy";

if (typeof $response == "undefined") {
  delete $request.headers["x-revenuecat-etag"];
  delete $request.headers["X-RevenueCat-ETag"];
  chxm1023.headers = $request.headers;
} else if (chxm1024 && chxm1024.subscriber) {
  chxm1024.subscriber.subscriptions = chxm1024.subscriber.subscriptions || {};
  chxm1024.subscriber.entitlements = chxm1024.subscriber.entitlements || {};
  const data = {
        "grace_period_expires_date": null,
        "purchase_date": "2024-01-14T18:59:05Z",
        "product_identifier": "com.palligroup.gpt3.yearlyyy",
        "expires_date": "2099-12-27T10:45:38Z"
      };
  const data_appleid = {
      "com.palligroup.gpt3.yearlyyy": {
        "original_purchase_date": "2024-01-14T18:59:06Z",
        "expires_date": "2099-12-27T10:45:38Z",
        "is_sandbox": false,
        "refunded_at": null,
        "auto_resume_date": null,
        "unsubscribe_detected_at": null,
        "grace_period_expires_date": null,
        "period_type": "annual",
        "purchase_date": "2024-01-14T18:59:05Z",
        "billing_issues_detected_at": null,
        "ownership_type": "PURCHASED",
        "store": "app_store",
        "store_transaction_id": "280001733195584"
      };
  const data1 = {
        "grace_period_expires_date" : null,
        "purchase_date" : "2023-12-24T10:45:38Z",
        "product_identifier" : "gpt_year",
        "expires_date" : "2099-12-27T10:45:38Z"
      };
  const data2 = {
        "grace_period_expires_date" : null,
        "purchase_date" : "2024-01-09T18:36:05Z",
        "product_identifier" : "2365",
        "expires_date" : "2099-01-12T18:36:05Z"
      };
   const data21 =  {
        "original_purchase_date": "2024-01-09T18:36:06Z",
        "expires_date": "2099-09-09T09:09:09Z",
        "is_sandbox": false,
        "refunded_at": null,
        "store_transaction_id": "480001769734560",
        "unsubscribe_detected_at": null,
        "grace_period_expires_date": null,
        "period_type": "trial",
        "purchase_date": "2024-01-09T18:36:05Z",
        "billing_issues_detected_at": null,
        "ownership_type": "PURCHASED",
        "store": "app_store",
        "auto_resume_date": null
      };
    const data3 = {
        "grace_period_expires_date" : null,
        "purchase_date" : "2024-01-10T07:33:56Z",
        "product_identifier" : "annual",
        "expires_date" : "2099-09-09T09:09:09Z"
      };
    
    const data31 = {
        "original_purchase_date" : "2024-01-10T07:33:57Z",
        "expires_date" : "2099-09-09T09:09:09Z",
        "is_sandbox" : false,
        "refunded_at" : null,
        "store_transaction_id" : "480001770307364",
        "unsubscribe_detected_at" : null,
        "grace_period_expires_date" : null,
        "period_type" : "annual",
        "purchase_date" : "2024-01-10T07:33:56Z",
        "billing_issues_detected_at" : null,
        "ownership_type" : "PURCHASED",
        "store" : "app_store",
        "auto_resume_date" : null
      };
    const data4 = {
        "original_purchase_date": "2024-01-12T05:48:02Z",
        "expires_date": "2099-09-09T09:09:09Z",
        "is_sandbox": false,
        "refunded_at": null,
        "store_transaction_id": "570001416479837",
        "unsubscribe_detected_at": null,
        "grace_period_expires_date": null,
        "period_type": "annual",
        "purchase_date": "2024-01-12T05:48:01Z",
        "billing_issues_detected_at": null,
        "ownership_type": "PURCHASED",
        "store": "app_store",
        "auto_resume_date": null
      };
    const data41 = {
        "grace_period_expires_date": null,
        "purchase_date": "2024-01-12T05:48:01Z",
        "product_identifier": "annual",
        "expires_date": "2099-09-09T09:09:09Z"
      };
    const data5 = {
        "original_purchase_date" : "2024-01-13T06:36:58Z",
        "expires_date" : "2099-09-09T09:09:09Z",
        "is_sandbox" : false,
        "refunded_at" : null,
        "store_transaction_id" : "570001417459984",
        "unsubscribe_detected_at" : null,
        "grace_period_expires_date" : null,
        "period_type" : "annual",
        "purchase_date" : "2024-01-13T06:36:57Z",
        "billing_issues_detected_at" : null,
        "ownership_type" : "PURCHASED",
        "store" : "app_store",
        "auto_resume_date" : null
      };
    const data51 = {
        "grace_period_expires_date" : null,
        "purchase_date" : "2024-01-13T06:36:57Z",
        "product_identifier" : "com.curiouscreatorsco.ChatLLM.pro.1year.notrial.49_99",
        "expires_date" : "2099-09-09T09:09:09Z"
      };
    const data6 = {
        "original_purchase_date": "2024-01-14T17:33:20Z",
        "expires_date": "2099-09-09T09:09:09Z",
        "is_sandbox": false,
        "refunded_at": null,
        "store_transaction_id": "570001418864092",
        "unsubscribe_detected_at": null,
        "grace_period_expires_date": null,
        "period_type": "lifetime",
        "purchase_date": "2024-01-14T17:33:19Z",
        "billing_issues_detected_at": null,
        "ownership_type": "PURCHASED",
        "store": "app_store",
        "auto_resume_date": null
      }
    const data61 = {
        "grace_period_expires_date": null,
        "purchase_date": "2024-01-14T17:33:19Z",
        "product_identifier": "com.aichatbot.askmeall.lifetime",
        "expires_date": "2099-09-09T09:09:09Z"
      };
    const data7 = {
        "original_purchase_date": "2023-12-26T19:35:38Z",
        "expires_date": "2099-09-09T09:09:09Z",
        "is_sandbox": false,
        "refunded_at": null,
        "store_transaction_id": "2000000500102462",
        "unsubscribe_detected_at": null,
        "grace_period_expires_date": null,
        "period_type": "normal",
        "purchase_date": "2024-01-14T18:34:03Z",
        "billing_issues_detected_at": null,
        "ownership_type": "PURCHASED",
        "store": "app_store",
        "auto_resume_date": null
      };
    const data71 = {
        "grace_period_expires_date": null,
        "purchase_date": "2024-01-14T18:34:03Z",
        "product_identifier": "impact.69.99.1y",
        "expires_date": "2099-09-09T09:09:09Z"
      };
  
  //delete chxm1024.subscriber.subscriptions[("impact.69.99.1y")];
  //delete chxm1024.subscriber.entitlements[("full_access")];
  delete chxm1024.subscriber.subscriptions[("impact.69.99.1w")];
  delete chxm1024.subscriber.subscriptions[("impact.69.99.1y")];
  delete chxm1024.subscriber.entitlements[("full_access")];
  delete chxm1024.subscriber.subscriptions[("com.aichatbot.askmeall.oneweek")];
  delete chxm1024.subscriber.entitlements[("pro")];
  delete chxm1024.subscriber.subscriptions[("com.palligroup.gpt3.weeklyyy")];
  delete chxm1024.subscriber.subscriptions[("weeklyIncludesTrial")];
  delete chxm1024.subscriber.subscriptions[("com.curiouscreatorsco.ChatLLM.pro.1year.3daytrial.49_99")];
  
  chxm1024.subscriber.entitlements[(name71)] = (data71);
  chxm1024.subscriber.subscriptions[(name7)] = (data7);
  chxm1024.subscriber.entitlements[(name61)] = (data61);
  chxm1024.subscriber.subscriptions[(name6)] = (data6);
  chxm1024.subscriber.entitlements[(name51)] = (data51);
  chxm1024.subscriber.subscriptions[(name5)] = (data5);
  chxm1024.subscriber.entitlements[(name41)] = (data41);
  chxm1024.subscriber.subscriptions[(name4)] = (data4);
  chxm1024.subscriber.entitlements[(name3)] = (data3);
  chxm1024.subscriber.subscriptions[(name31)] = (data31);
  chxm1024.subscriber.entitlements[(name2)] = (data2);
  chxm1024.subscriber.subscriptions[(name21)] = (data21);
  chxm1024.subscriber.entitlements[(name1)] = (data1);
  chxm1024.subscriber.entitlements[(name)] = (data);
  chxm1024.subscriber.subscriptions[(appid)] = (data_appleid);
  
  
  chxm1023.body = JSON.stringify(chxm1024);
}

$done(chxm1023);
