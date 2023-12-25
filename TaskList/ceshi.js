
var Echo = JSON.parse($response.body);
Echo = {
  "success" : true,
  "data" : {
    "totalCreditGpt4" : 7,
    "isPremium" : true,
    "totalCreditImage" : 10,
    "creditGpt4" : 7,
    "creditImage" : 10,
    "totalCredit" : 150,
    "userId" : "7F4C8B872C7649D88A226C02D88DE4A2",
    "credit" : 150,
    "creditBard" : 150,
    "creditGpt4Vision" : 15,
    "totalCreditGpt4Vision" : 15,
    "totalCreditBard" : 150,
    "creditDocument" : 10,
    "totalCreditDocument" : 10
  },
  "time" : "2023-12-24T23:33:01.404Z"
}


$done({body: JSON.stringify(Echo)});
