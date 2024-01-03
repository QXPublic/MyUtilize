
let yolo = JSON.parse($response.body);
yolo.data.user.isPremium = true;
yolo.data.user.isSuperUser = true;
yolo.apiVersion = "v3";
$done({ body: JSON.stringify(yolo)});
