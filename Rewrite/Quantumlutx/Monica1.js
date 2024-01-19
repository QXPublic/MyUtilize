
/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/vip\/get_vip_status url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica1.js

[mitm]
hostname = monica.im
*/
var body = $response.body;

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
  body = JSON.stringify(obj);
  
  $done({ body });
