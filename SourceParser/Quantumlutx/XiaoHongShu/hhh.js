/*
[rewrite_local]

^http?:\/\/sns-img-qc\.xhscdn\.com\/comment\/\w+ url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/SourceParser/Quantumlutx/hhh.js

[mitm]
hostname = sns-img-qc.xhscdn.com
*/
const hongshu = {};
if (typeof $response == "undefined") {
delete $request.headers["X-XHS-TraceId"];
hongshu.headers = $request.headers;
}
$done(hongshu);