/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/usage\/get_multi_module_usage url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica2.js

[mitm]
hostname = monica.im
*/


var obj = JSON.parse($response.body);

    obj = {
  "msg" : "ok",
  "data" : [
    {
      "module" : "basic_query",
      "rewarded_total" : 0,
      "plan_total" : 999999,
      "plan_remaining" : 40,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "genius_bot",
      "rewarded_total" : 0,
      "plan_total" : 999999,
      "plan_remaining" : 0,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "artist_bot",
      "rewarded_total" : 0,
      "plan_total" : 999999,
      "plan_remaining" : 0,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "web_search",
      "rewarded_total" : 0,
      "plan_total" : 999999,
      "plan_remaining" : 5,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "reading_pdf",
      "rewarded_total" : 0,
      "plan_total" : 999999,
      "plan_remaining" : 10,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "claude_100k",
      "rewarded_total" : 0,
      "plan_total" : 999999,
      "plan_remaining" : 0,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "claude2",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 0,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "reading",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 2,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "youtube_summarize",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 2,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    }
  ],
  "code" : 0
}
$done({body : JSON.stringify(obj)});