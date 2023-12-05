const url = "http://ip234.in/ip.json";

$http.get(url).then(response => {
    const data = response.body;
    const ipInfo = JSON.parse(data);
    
    if (ipInfo && ipInfo.hasOwnProperty('type')) {
        // 检测到 IP 类型存在
        let ipType = ipInfo.type;
        // 输出 IP 类型
        console.log(`当前 IP 类型为: ${ipType}`);
        $done({title: "IP 类型检测", message: `当前 IP 类型为: ${ipType}`});
    } else {
        // 未检测到 IP 类型
        console.log("无法检测到当前 IP 类型。");
        $done({title: "IP 类型检测", message: "无法检测到当前 IP 类型。"});
    }
}).catch(error => {
    // 出现错误
    console.error(`请求出错: ${error}`);
    $done({title: "IP 类型检测", message: "请求出错，请检查网络连接。"});
});
