/****************
[rewrite_local]
^https?:\/\/api\.novaapp\.ai\/api\/v1\/users\/\w+ url script-response-body 

[mitm]
hostname = api.novaapp.ai
*****************/
var Echo = JSON.parse($response.body);
Echo = {
  "success" : true,
  "data" : {
    "totalCreditGpt4" : 999,
    "isPremium" : true,
    "totalCreditImage" : 999,
    "creditGpt4" : 999,
    "creditImage" : 999,
    "totalCredit" : 150,
    "userId" : "7F4C8B872C7649D88A226C02D88DE4A2",
    "credit" : 999,
    "creditBard" : 999,
    "creditGpt4Vision" : 999,
    "totalCreditGpt4Vision" : 99,
    "totalCreditBard" : 999,
    "creditDocument" : 999,
    "totalCreditDocument" : 999
  },
  "time" : "2023-12-24T23:33:01.404Z"
}

$done({body: JSON.stringify(Echo)});
