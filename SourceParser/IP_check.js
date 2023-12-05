const url = 'http://ip234.in/ip.json';

$httpClient.get(url, function (error, response, body) {
    if (!error && response.statusCode === 200) {
        $done(body);
    } else {
        console.error('Failed to fetch content:', error);
        $done();
    }
});
