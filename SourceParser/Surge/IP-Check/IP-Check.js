/*
 * 由@congcong0806编写
 * 原脚本地址：https://github.com/congcong0806/surge-list/blob/master/Script/ipcheck.js
 * 由@Rabbit-Spec修改
 * 更新日期：2022.08.14
 * 版本：1.5
 */

let url = "https://api.ipdata.co/?api-key=64e914705286ef6ac7ee40f52ad2ab69d90401cbbacfdace0948cbca"

$httpClient.get(url, function(error, response, data){
    let jsonData = JSON.parse(data)

    let emoji = getFlagEmoji(jsonData.countryCode)
    let city = jsonData.city
    let isp = jsonData.asn.name
    let type = jsonData.asn.name
  body = {
    title: "节点信息",
    content: `IP信息：${type}\n运营商：${isp}\n所在地：${emoji}${country} - ${city}`,
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
