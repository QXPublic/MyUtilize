// 2023-12-15 14:12:00
let url = $request.url;
let body = $response.body;
console.log('dy123_let url_in'+url);
console.log('xueqiuxq=========================START================================================');

if (url.includes("timeline_tab_name")) {
      let obj = JSON.parse(body);
      obj.data.timeline_tab_name.content.name="nnnnjjjj";
      obj.data.timeline_tab_name.update_type=0;
      obj.data.profileMenuConfig_anonymous_V12.content[1].list=[];
      obj.data.trade_guojin_new_system.content.open=false;
      obj.data.trade_guolian_new_system.content.open=false;
      //obj.data.screen_shot_switch.content.isOpen=false;
      //obj.data.hot_timeline_status_config.content.value=false;
      obj.data.new_ad_engine.content.value=false;

      obj.data.home_tab_dynamic.content.switch=false;
      obj.data.home_tab_dynamic.content.icon_url="";
      obj.data.home_tab_dynamic.content.url="";
      obj.data.home_tab_dynamic.content.is_web_url=false;

      obj.data.trade_open_account_promotion_url={ };

      obj.data.community_ad_download_msg= { };

      obj.data.newhome_market_enable.content.enable=false;
      obj.data.snowpard_ad_switch.content.value=0;
      obj.data.xq_feed_preload_pic_switch.content.enable=false;
      obj.data.xq_feed_render_animation_switch.content.enable=false;
      obj.data.snowpard_ad_switch_recommend.content.value=0;
      obj.data.snowpard_ad_switch_search_banner.content.value=0;
      obj.data.snowpard_ad_switch_detail_comment.content.value=0;   
      obj.data.snowpard_ad_switch_search_text.content.value=0;
      obj.data.snowpard_ad_switch_recommend_banner.content.value=0;
      obj.data.status_detail_ad_strategy.content=[ ];
      obj.data.bee_config_banner_asset.content.value=0;
      body = JSON.stringify(obj);
      console.log('xq123替换body成功'+JSON.stringify(obj));
      $done({ body });
    }

if (url.includes("/analysis/home/my_tab.json")) {
      let obj = JSON.parse(body);
      const index = obj.data.list.findIndex(item => item.id === 40);

      if (index !== -1) {
        // 将找到的对象置为空对象
        obj.data.list[index] = {};
        }
      body = JSON.stringify(obj);
      console.log('xq456替换body成功'+JSON.stringify(obj));

      $done({ body });
    }
else {
    $done();
    console.log('xq789替换body失败'+url);
}

console.log('xueqiuxq===============================END==========================================');
