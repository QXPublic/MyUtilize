const url = "http://ip234.in/ip.json";

$http.get(url).then(response => {
    let ipData = response.data;
    let ipType = ipData.type;
    let result;

    // Check if we have an IP type returned
    if (ipType) {
        result = {
            title: "IP Type",
            content: ipType,
            icon: "globe"
        };
    } else {
        result = {
            title: "IP Type",
            content: "Unknown",
            icon: "exclamationmark.triangle"
        };
    }

    // Call $done to return the result to Surge
    $done(result);
}).catch(error => {
    // Handle the error
    let result = {
        title: "IP Type",
        content: "Error",
        icon: "xmark.circle"
    };
    $done(result);
});
