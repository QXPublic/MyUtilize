/*

[rewrite_local]


^https?:\/\/www\.qobuz\.com\/api\.json\/[0-9].[0-9]\/user\/login url script-response-body https://raw.githubusercontent.com/QXPublic/MyUtilize/main/Rewrite/Quantumlutx/Qobuz.js

[mitm] 

hostname = www.qobuz.com

*/


var obj = JSON.parse($response.body);
    obj = {
  "user" : {
    "language_code" : "en",
    "lastname" : "",
    "subscription" : null,
    "firstname" : "",
    "country_code" : "GB",
    "country" : "GB",
    "store_features" : {
      "wallet" : true,
      "opt_in" : true,
      "radio" : true,
      "music_import" : true,
      "download" : true,
      "club" : true,
      "autoplay" : true,
      "inapp_purchase_subscripton" : true,
      "editorial" : true,
      "streaming" : true,
      "weeklyq" : true
    },
    "store" : "GB-en",
    "creation_date" : "2023-12-26",
    "externals" : {

    },
    "last_update" : {
      "favorite_track" : 1703619074,
      "favorite_artist" : 1703619074,
      "favorite" : 1703619074,
      "purchase" : 1703619074,
      "favorite_album" : 1703619074,
      "playlist" : 1703619074
    },
    "player_settings" : [

    ],
    "id" : 2832293,
    "email" : "zhuce2099@gmail.com",
    "publicId" : "qobuz:user:zgq0p002v7za5",
    "login" : "yolozu",
    "avatar" : "https://www.gravatar.com/avatar/3e77faf4eec0c9af63d82de1b2b27bbe?s=50&d=mm",
    "display_name" : "zhuce2099@gmail.com",
    "age" : 24,
    "genre" : "male",
    "credential" : {
      "id" : 2034874,
      "label" : "streaming-studio",
      "description" : "Subscriber Qobuz Studio",
      "parameters" : {
        "lossy_streaming" : true,
        "label" : "Qobuz Studio",
        "mobile_streaming" : true,
        "included_format_group_ids" : [
          1,
          2,
          3,
          4
        ],
        "hires_purchases_streaming" : true,
        "short_label" : "Studio",
        "source" : "appstore-test",
        "offline_streaming" : true,
        "hfp_purchase" : false,
        "lossless_streaming" : true,
        "hires_streaming" : true,
        "color_scheme" : {
          "logo" : "#B8D729"
        }
      }
    },
    "zone" : "GB",
    "device" : {
      "id" : 33320255,
      "device_model" : "iPhone",
      "device_manufacturer_id" : "37600FD0-8F93-415A-A734-D754169E3F94",
      "device_os_version" : "16.7.2",
      "device_platform" : "iphone_family"
    }
  },
  "user_auth_token" : "HlHeTCRzsAo3HkeIYTv6S-s89sr_GXK1BISx2sbfjt1aXKADbB46_1J_qLk4BtcOO4zb3fyg52zfYkxE5OvPyA"
}
$done({body : JSON.stringify(obj)});