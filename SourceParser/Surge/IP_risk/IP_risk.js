/*
 * 由@congcong0806编写
 * 原脚本地址：https://github.com/congcong0806/surge-list/blob/master/Script/ipcheck.js
 * 由@Rabbit-Spec修改
 * 更新日期：2022.08.14
 * 版本：1.5
 */

let url = "http://ip234.in/f.json"

$httpClient.get(url, function(error, response, data){
    let jsonData = JSON.parse(data)
    let data1 = jsonData.data
    let risk = data1.risk
    let score = data1.score
    
  body = {
    title: "节点风险信息",
    content: `IP风险：${risk}\n风险指数：${score}`,
    icon: "globe.asia.australia.fill"
  }
  $done(body);
});

function getFlagEmoji(countryCode) {
      if (countryCode.toUpperCase() == 'TW') {
    countryCode = 'CN'
  }
  const codePoints = countryCode
    .toUpperCase()
    .split('')
    .map(char => 127397 + char.charCodeAt())
  return String.fromCodePoint(...codePoints)

}
