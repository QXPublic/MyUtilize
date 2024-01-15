/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/vip\/\w+ url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica-Ai.js

[mitm]
hostname = monica.im
*/
var body = $response.body;
//var url = $request.url;

//会员
    var obj = JSON.parse(body);
  obj.vip_status.vip_version = "elite";
  obj.vip_status.point_period_end = 1706745599;
  obj.vip_status.point_period_start =  1704067200;
  obj.vip_status.current_period_end = 1705594362;
  obj.vip_status.version_at_period_end = "elite";
  obj.vip_status.current_period_start = 1705335162;
  obj.vip_status.payment_platform = "apple";
  obj.vip_status.interval_at_period_end =  "year";
  obj.vip_status.enable_new_user_yearly_reward =  false;
  obj.vip_status.interval_count = 1;
  obj.vip_status.reward_badge = 0;
  obj.vip_status.total_point = 999999;
  obj.vip_status.can_use_trial = false;
  obj.vip_status.interval = "year";


body = JSON.stringify(obj);
