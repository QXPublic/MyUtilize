
const apiURL = "https://api.ipdata.co/?api-key=64e914705286ef6ac7ee40f52ad2ab69d90401cbbacfdace0948cbca";

function onResponse(request, response) {
  // 发送请求获取数据
  $httpClient.get(apiURL, (error, response, data) => {
    if (error || response.status !== 200) {
      console.error(`Error: ${error}`);
      $done({});
    } else {
      // 确保返回 JSON 数据
      let jsonData;
      try {
        jsonData = JSON.parse(data);
      } catch (parseError) {
        console.error("JSON parse error: " + parseError);
        $done({});
      }
      // 向 Surge 响应体中写入数据
      let IP = jsonData.ip
      body = {
    title: "节点信息",
    content: `IP信息：${IP}`,
      }
      $done({body});
    }
  });
}

module.exports = {onResponse};
