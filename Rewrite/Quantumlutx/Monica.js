
/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/(vip\/get_vip_status|usage\/get_multi_module_usage) url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica.js

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
  var data = ojb.data

   data.forEach(function(item) {
    item.plan_total = 999999;
    item.plan_period = "forever";
});


body = console.log(JSON.stringify(data));

}

$done({ body });

