/*

[rewrite_local]

^https?:\/\/api\.sparrow\.arafas\.com\/verify-subscription url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/TaskList/add.js 

[MITM]
hostname = api.sparrow.arafas.com

*/
var yolo = JSON.parse($response.body);
yolo = {
  "buildNumber" : "1.0.1.20232604",
  "apiVersion" : "v1",
  "data" : {
    "showPaywall" : true,
    "user" : {
      "totalTokenSpentAllTime" : 0,
      "referralCode" : "V4PBJ2BO",
      "isDeleted" : false,
      "__v" : 3,
      "deviceId" : "5517752E-BEC3-4B9A-A6A1-FA58487D93FF",
      "isPremium" : true,
      "creditsEarnedForReferral" : 100,
      "totalCreditSpent" : 100,
      "_id" : "6595b492fc6528bca31b5ca1",
      "name" : "User_026237463949",
      "totalTokenSpent" : 100,
      "purchaseIds" : [

      ],
      "email" : "User_026237463949",
      "ultraCredits" : 100,
      "isSuperUser" : true,
      "totalUltraCreditSpent" : 100,
      "appleId" : "",
      "package" : "",
      "credits" : 100”,
      "isEmailVerified" : false
    }
  }
};
$done({body:JSON.stringify(yolo)});
