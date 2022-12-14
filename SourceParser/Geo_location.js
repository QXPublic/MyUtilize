/**
 
  Thanks for the author @XIAO_KOP

  **/

// var content= `<p style="text-align: center; font-family: -apple-system; font-size: large; font-weight: bold">` + response.body + `</p>`;

  var url = "https://api.ip.sb/geoip"
  var opts = {
      policy: $environment.params
  };
  var myRequest = {
      url: url,
      opts: opts,
      timeout: 4000
  };
 
  var message = ""
  const paras = ["ip","isp","country_code","city"]
  const paran = ["IP","ISP","ć°ćș","ććž"]
  $task.fetch(myRequest).then(response => {
    message = response? json2info(response.body,paras) : ""
      $done({"title": "    đ IP.SB æ„èŻąç»æ", "htmlMessage": message});
  }, reason => {
    message = "</br></br>đ æ„èŻąè¶æ¶"
    message = `<p style="text-align: center; font-family: -apple-system; font-size: large; font-weight: bold;">` + message + `</p>`
      $done({"title": "đ IP.SB æ„èŻąç»æ", "htmlMessage": message});
  })


function json2info(cnt,paras) {
  var res = "------------------------------"
  cnt =JSON.parse(cnt)
  for (i=0;i<paras.length;i++) {
    cnt[paras[i]] = paras[i] == "country_code"? cnt[paras[i]]+" âŠ"+flags.get(cnt[paras[i]].toUpperCase())+"â§":cnt[paras[i]]
    res = cnt[paras[i]]?   res +"</br><b>"+ "<font  color=>" +paran[i] + "</font> : " + "</b>"+ "<font  color=>"+cnt[paras[i]] +"</font></br>" : res
  }
  res =res+ "------------------------------"+"</br>"+"<font color=#6959CD>"+"<b>èçč</b> â " + $environment.params+ "</font>"
  res =  `<p style="text-align: center; font-family: -apple-system; font-size: large; font-weight: thin">` + res + `</p>`
  return res
}


var flags = new Map([[ "AC" , "đŠđš" ] ,["AE","đŠđȘ"], [ "AF" , "đŠđ«" ] , [ "AI" , "đŠđź" ] , [ "AL" , "đŠđ±" ] , [ "AM" , "đŠđČ" ] , [ "AQ" , "đŠđ¶" ] , [ "AR" , "đŠđ·" ] , [ "AS" , "đŠđž" ] , [ "AT" , "đŠđč" ] , [ "AU" , "đŠđș" ] , [ "AW" , "đŠđŒ" ] , [ "AX" , "đŠđœ" ] , [ "AZ" , "đŠđż" ] , ["BA", "đ§đŠ"], [ "BB" , "đ§đ§" ] , [ "BD" , "đ§đ©" ] , [ "BE" , "đ§đȘ" ] , [ "BF" , "đ§đ«" ] , [ "BG" , "đ§đŹ" ] , [ "BH" , "đ§đ­" ] , [ "BI" , "đ§đź" ] , [ "BJ" , "đ§đŻ" ] , [ "BM" , "đ§đČ" ] , [ "BN" , "đ§đł" ] , [ "BO" , "đ§đŽ" ] , [ "BR" , "đ§đ·" ] , [ "BS" , "đ§đž" ] , [ "BT" , "đ§đč" ] , [ "BV" , "đ§đ»" ] , [ "BW" , "đ§đŒ" ] , [ "BY" , "đ§đŸ" ] , [ "BZ" , "đ§đż" ] , [ "CA" , "đšđŠ" ] , [ "CF" , "đšđ«" ] , [ "CH" , "đšđ­" ] , [ "CK" , "đšđ°" ] , [ "CL" , "đšđ±" ] , [ "CM" , "đšđČ" ] , [ "CN" , "đšđł" ] , [ "CO" , "đšđŽ" ] , [ "CP" , "đšđ”" ] , [ "CR" , "đšđ·" ] , [ "CU" , "đšđș" ] , [ "CV" , "đšđ»" ] , [ "CW" , "đšđŒ" ] , [ "CX" , "đšđœ" ] , [ "CY" , "đšđŸ" ] , [ "CZ" , "đšđż" ] , [ "DE" , "đ©đȘ" ] , [ "DG" , "đ©đŹ" ] , [ "DJ" , "đ©đŻ" ] , [ "DK" , "đ©đ°" ] , [ "DM" , "đ©đČ" ] , [ "DO" , "đ©đŽ" ] , [ "DZ" , "đ©đż" ] , [ "EA" , "đȘđŠ" ] , [ "EC" , "đȘđš" ] , [ "EE" , "đȘđȘ" ] , [ "EG" , "đȘđŹ" ] , [ "EH" , "đȘđ­" ] , [ "ER" , "đȘđ·" ] , [ "ES" , "đȘđž" ] , [ "ET" , "đȘđč" ] , [ "EU" , "đȘđș" ] , [ "FI" , "đ«đź" ] , [ "FJ" , "đ«đŻ" ] , [ "FK" , "đ«đ°" ] , [ "FM" , "đ«đČ" ] , [ "FO" , "đ«đŽ" ] , [ "FR" , "đ«đ·" ] , [ "GA" , "đŹđŠ" ] , [ "GB" , "đŹđ§" ] , [ "HK" , "đ­đ°" ] ,["HU","đ­đș"], [ "ID" , "đźđ©" ] , [ "IE" , "đźđȘ" ] , [ "IL" , "đźđ±" ] , [ "IM" , "đźđČ" ] , [ "IN" , "đźđł" ] , [ "IS" , "đźđž" ] , [ "IT" , "đźđč" ] , [ "JP" , "đŻđ”" ] , [ "KR" , "đ°đ·" ] , [ "LU" , "đ±đș" ] , [ "MO" , "đČđŽ" ] , [ "MX" , "đČđœ" ] , [ "MY" , "đČđŸ" ] , [ "NL" , "đłđ±" ] , [ "PH" , "đ”đ­" ] , [ "RO" , "đ·đŽ" ] , [ "RS" , "đ·đž" ] , [ "RU" , "đ·đș" ] , [ "RW" , "đ·đŒ" ] , [ "SA" , "đžđŠ" ] , [ "SB" , "đžđ§" ] , [ "SC" , "đžđš" ] , [ "SD" , "đžđ©" ] , [ "SE" , "đžđȘ" ] , [ "SG" , "đžđŹ" ] , [ "TH" , "đčđ­" ] , [ "TN" , "đčđł" ] , [ "TO" , "đčđŽ" ] , [ "TR" , "đčđ·" ] , [ "TV" , "đčđ»" ] , [ "TW" , "đšđł" ] , [ "UK" , "đŹđ§" ] , [ "UM" , "đșđČ" ] , [ "US" , "đșđž" ] , [ "UY" , "đșđŸ" ] , [ "UZ" , "đșđż" ] , [ "VA" , "đ»đŠ" ] , [ "VE" , "đ»đȘ" ] , [ "VG" , "đ»đŹ" ] , [ "VI" , "đ»đź" ] , [ "VN" , "đ»đł" ] , [ "ZA" , "đżđŠ"]])
