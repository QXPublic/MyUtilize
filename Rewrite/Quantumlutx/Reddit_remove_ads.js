/*
脚本引用 @xream
# Reddit
[mitm]
hostname = gql.reddit.com, gql-fed.reddit.com
# 过滤推广 关NSFW提示 感谢【xream】分享
[rewrite_local]
^https?:\/\/gql(-fed)?\.reddit\.com url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Reddit_remove_ads.js
*/
let body;
try {
  body = JSON.parse($response.body.replace(/"isNsfw":true/g, '"isNsfw":false'))
  if (body.data?.children?.commentsPageAds) {
    body.data.children.commentsPageAds = []
  } 
  for (const [k, v] of Object.entries(body.data)) {
    if (v?.elements?.edges) {
      body.data[k].elements.edges = v.elements.edges.filter(
        i =>
          !['AdPost'].includes(i?.node?.__typename) &&
          !i?.node?.cells?.some(j => j?.__typename === 'AdMetadataCell') &&
          !i?.node?.adPayload
      );
    }
  }

  
} catch (e) {
  console.log(e);
} finally {
  $done(body ? { body: JSON.stringify(body) } : {});
}
