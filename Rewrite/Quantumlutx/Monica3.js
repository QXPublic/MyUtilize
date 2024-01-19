/*

[rewrite_local]

^https?:\/\/monica\.im\/api\/usage\/get_mobile_usage_info url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Monica3.js

[mitm]
hostname = monica.im
*/


var obj = JSON.parse($response.body);

    obj = {
  "msg" : "ok",
  "data" : [
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/basic_queries.png",
      "title" : "Queries",
      "usage_model" : "basic_query"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/gpt4.png",
      "title" : "GPT-4",
      "usage_model" : "genius_bot"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/images.png",
      "title" : "Images",
      "usage_model" : "artist_bot"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/web_search.png",
      "title" : "Web Search",
      "usage_model" : "web_search"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/pdf.png",
      "title" : "ChatPDF",
      "usage_model" : "reading_pdf"
    },
    {
      "is_pro_feature" : true,
      "icon" : "https://assets.monica.im/assets/icon/mobile/claude.png",
      "title" : "Claude-100K",
      "usage_model" : "claude_100k"
    },
    {
      "is_pro_feature" : true,
      "icon" : "",
      "title" : "Claude-2",
      "usage_model" : "claude2"
    },
    {
      "is_pro_feature" : true,
      "icon" : "",
      "title" : "Web Summary",
      "usage_model" : "reading"
    },
    {
      "is_pro_feature" : true,
      "icon" : "",
      "title" : "Youtube Summarize",
      "usage_model" : "youtube_summarize"
    }
  ],
  "code" : 0
}
$done({body : JSON.stringify(obj)});