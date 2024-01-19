
/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/(vip\/get_vip_status|usage\/get_multi_module_usage|usage\/get_mobile_usage_info) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica.js

[mitm]
hostname = monica.im
*/
var body = $response.body;
var url = $request.url;
if (url.indexOf('vip/get_vip_status') != -1) {
  var obj = JSON.parse(body);
  obj.vip_status.point_period_end = 1706745599;
  obj.vip_status.vip_version = "elite";
  obj.vip_status.point_period_start = 1705594362;
  obj.vip_status.cancel_at_period_end = false;
  obj.vip_status.current_period_end = 4073587199;
  obj.vip_status.version_at_period_end = "elite";
  obj.vip_status.current_period_start = 1705335162;
  obj.vip_status.interval_at_period_end = "year";
  obj.vip_status.total_point = 999999;
  obj.vip_status.interval = "year";
  obj.vip_status.interval_at_period_end =
  obj.vip_status.interval_at_period_end =
  obj.vip_status.interval_at_period_end =
  obj.vip_status.interval_at_period_end =
  obj.vip_status.interval_at_period_end =
  body = JSON.stringify(obj);
  }else if (url.indexOf('usage/get_multi_module_usage') != -1) {
  var obj = JSON.parse(body);
  var data = {
  "msg" : "ok",
  "data" : [
    {
      "module" : "basic_query",
      "rewarded_total" : 0,
      "plan_total" : 99999,
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
      "plan_total" : 99999,
      "plan_remaining" : 0,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "web_search",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 5,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "reading_pdf",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 10,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "claude_100k",
      "rewarded_total" : 0,
      "plan_total" : 99999,
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
      "plan_period" : "{
  "msg" : "ok",
  "data" : [
    {
      "module" : "basic_query",
      "rewarded_total" : 0,
      "plan_total" : 99999,
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
      "plan_total" : 99999,
      "plan_remaining" : 0,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "web_search",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 5,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "reading_pdf",
      "rewarded_total" : 0,
      "plan_total" : 99999,
      "plan_remaining" : 10,
      "is_trial" : false,
      "rewarded_remaining" : 0,
      "plan_period" : "forever"
    },
    {
      "module" : "claude_100k",
      "rewarded_total" : 0,
      "plan_total" : 99999,
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
}"
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
body = JSON.stringify(obj);
}else if (url.indexOf('usage/get_mobile_usage_info') != -1) {
  var obj = JSON.parse(body);
  var obj = {
  "msg" : "ok",
  "data" : [
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/basic_queries.png",
      "title" : "Queries",
      "usage_model" : "basic_query"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/gpt4.png",
      "title" : "GPT-4",
      "usage_model" : "genius_bot"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/images.png",
      "title" : "Images",
      "usage_model" : "artist_bot"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/web_search.png",
      "title" : "Web Search",
      "usage_model" : "web_search"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/pdf.png",
      "title" : "ChatPDF",
      "usage_model" : "reading_pdf"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/claude.png",
      "title" : "Claude-100K",
      "usage_model" : "claude_100k"
    },
    {
      "is_pro_feature" : true,
      "icon" : "",
      "title" : "Claude-2",
      "usage_model" : "claude2"
    },
    {
      "is_pro_feature" : true,
      "icon" : "",
      "title" : "Web Summary",
      "usage_model" : "reading"
    },
    {
      "is_pro_feature" : true,
      "icon" : "",
      "title" : "Youtube Summarize",
      "usage_model" : "youtube_summarize"
    }
  ],
  "code" : 0
}

body = JSON.stringify(obj);
  }

$done({ body });

