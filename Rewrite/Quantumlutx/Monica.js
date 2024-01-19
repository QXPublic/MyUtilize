
/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/vip\/get_vip_status url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica.js

[mitm]
hostname = monica.im
*/
var obj = JSON.parse($response.body);
     obj = {
  "msg" : "ok",
  "vip_status" : {
    "used_web_search_point" : 0,
    "point_period_end" : 1706745599,
    "vip_version" : "elite",
    "total_web_search_point" : 5,
    "point_period_start" : 1705594362,
    "invite_event_start" : -1,
    "user_id" : 7521490,
    "cancel_at_period_end" : true,
    "current_period_end" : 4073587199,
    "used_point" : 0,
    "version_at_period_end" : "elite",
    "current_period_start" : 1705335162,
    "payment_platform" : "apple",
    "from_exchange_code" : false,
    "invite_event_id" : "genius_invite_v1",
    "invite_event_end" : -1,
    "interval_at_period_end" : "year",
    "ext_reward_records" : [

    ],
    "enable_new_user_yearly_reward" : false,
    "try_vip_feature_left_days" : 0,
    "interval_count" : 1,
    "reward_badge" : 0,
    "giveaway_vip_status" : null,
    "total_point" : 999999,
    "can_use_trial" : false,
    "total_reading_point" : 2,
    "enable_giveaway_vip_days" : 0,
    "has_customer" : false,
    "interval" : "year",
    "used_reading_point" : 0,
    "on_trial" : false,
    "using_giveaway_vip" : false
  },
  "code" : 0
}

$done({body : JSON.stringify(obj)});

