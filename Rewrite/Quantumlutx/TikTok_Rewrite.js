# TikTok TaiWan
/*
###换区：在[rewrite_local]中添加下句重写，并将CN改为想看的国家/地区的2位大写英文简写 JP（日本）｜KR（韩国）｜UK（英国）｜US（美国）｜TW（台湾）
/*

[mitm]
hostname = *.tiktokv.com, *.byteoversea.com, *.tik-tokapi.com,-*snssdk.com, -*amemv.com

[rewrite_local]
(?<=_region=)CN(?=&) url 307 TW
(?<=&mcc_mnc=)4 url 307 2
^(https?:\/\/(tnc|dm)[\w-]+\.\w+\.com\/.+)(\?)(.+) url 302  $1$3
(?<=\d\/\?\w{7}_\w{4}=)1[6-9]..(?=.?.?&) url 307 17
