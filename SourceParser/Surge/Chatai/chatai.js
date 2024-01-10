const chxm1023 = {};
const chxm1024 = JSON.parse(typeof $response != "undefined" && $response.body || null);

const name = "Advanced";
const name1 = "Unlimited";
const name2 = "echo_pro";
const name21 = "2365";
const name3 = "Premium";
const name31 = "annual";

const appid = "com.palligroup.gpt3.yearlyyy";

if (typeof $response == "undefined") {
  delete $request.headers["x-revenuecat-etag"];
  delete $request.headers["X-RevenueCat-ETag"];
  chxm1023.headers = $request.headers;
} else if (chxm1024 && chxm1024.subscriber) {
  chxm1024.subscriber.subscriptions = chxm1024.subscriber.subscriptions || {};
  chxm1024.subscriber.entitlements = chxm1024.subscriber.entitlements || {};
  const data = {
	"product_identifier": (appid),
	"expires_date": "2099-09-09T09:09:09Z",
	"purchase_date": "2022-09-09T09:09:09Z"
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
        "period_type" : "trial",
        "purchase_date" : "2024-01-10T07:33:56Z",
        "billing_issues_detected_at" : null,
        "ownership_type" : "PURCHASED",
        "store" : "app_store",
        "auto_resume_date" : null
      };
  
  chxm1024.subscriber.entitlements[(name3)] = (data3);
  chxm1024.subscriber.subscriptions[(name31)] = (data31);
  chxm1024.subscriber.entitlements[(name2)] = (data2);
  chxm1024.subscriber.subscriptions[(name21)] = (data21);
  chxm1024.subscriber.entitlements[(name1)] = (data1);
  chxm1024.subscriber.entitlements[(name)] = (data);
  chxm1024.subscriber.subscriptions[(appid)] = {  ...data,	"original_purchase_date": "2022-09-09T09:09:09Z",	"store": "app_store",	"ownership_type": "PURCHASED"};
  
  
  chxm1023.body = JSON.stringify(chxm1024);
}

$done(chxm1023);
