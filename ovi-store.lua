dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}
local downloadsize = {}

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  local html = nil
  
  if downloaded[url] == true or addedtolist[url] == true then
    return false
  end
  
  if item_type == "app" and (downloaded[url] ~= true and addedtolist[url] ~= true) then
    if string.match(url, "[^0-9]"..item_value.."[0-9][^0-9]") and not string.match(url, "https?://store%.ovi%.com/content/"..item_value.."[0-9]/applications%?categoryId=[0-9]+") then
      return verdict
    elseif html == 0 then
      return verdict
    else
      return false
    end
  end
  
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  
  local function check(url)
    if (downloaded[url] ~= true and addedtolist[url] ~= true) and not string.match(url, "https?://store%.ovi%.com/content/"..item_value.."[0-9]/applications%?categoryId=[0-9]+") then
      table.insert(urls, { url=url })
      addedtolist[url] = true
    end
  end

  if item_type == "app" then
    if string.match(url, "https?://store%.ovi%.com/content/[0-9]+/Download") then
      html = read_file(file)
      for newurl in string.gmatch(html, "(https?://[^\n]+)") do
        if string.match(newurl, "https?://[a-z]%.ovi%.com/[a-z]/[a-z]/store/") or string.match(newurl, " https?://wam%.browser%.ovi%.com/[^/]+/v1_0/clients/") then
          check(newurl)
        end
      end
      local number = string.match(url, "https?://store%.ovi%.com/content/([0-9]+)/Download")
      local devices = {"109", "110", "1100", "111", "1110", "112", "1120", "113", "1680c", "2010", "2020", "2030", "2050", "206", "206_DS", "2060", "207_1", "208_1", "208", "2220s", "2323c", "2330c", "2600c", "2610", "2626", "2630", "2660", "2680s", "2690", "2700c", "2710", "2720f", "2730c", "2760", "3000", "301", "301_DS", "3020", "3030", "3050", "3060", "3080", "3090", "3109c", "3110", "3110c", "3120c", "3208c", "3230", "3250", "3500c", "3600s", "3610f", "3710f", "3720c", "500", "5000", "5070", "5130", "515", "515_2", "5200", "5220", "5228", "5230", "5233", "5235", "5250", "5300", "5310", "5320", "5330MobileTV", "5530xm", "5610", "5630", "5700", "5730", "5800", "603", "6060", "6070", "6080", "6085", "6101", "6103", "6110Navigator", "6111", "6120c", "6121c", "6124c", "6125", "6131", "6151", "6210", "6212c", "6220c", "6230", "6233", "6260Slide", "6263", "6267", "6270", "6280", "6288", "6290", "6300", "6300i", "6301", "6303c", "6303ic", "6350", "6500c", "6500s", "6555", "6600f", "6600s", "6600is", "6630", "6650f", "6670", "6680", "6681", "6700c", "6700Slide", "6702", "6710Navigator", "6720c", "6730c", "6750", "6760s", "6788", "6788i", "6790slide", "6790_Surge", "700", "701", "7020", "702T", "7070", "7100Supernova", "7210Supernova", "7230", "7270", "7310Supernova", "7360", "7370", "7373", "7390", "7500", "7510Supernova", "7610Supernova", "7900", "801T", "808_pureview", "8600luna", "8800", "Asha_200", "Asha_201", "Asha_202", "Asha_203", "Asha_205", "Asha_205_DS", "210_3", "210", "230s", "Asha_230", "Asha_300", "Asha_302", "Asha_303", "305", "306", "Asha_308", "Asha_309", "311", "Asha_500", "500s", "501", "501_DS", "502", "503a", "503", "C1-01", "C1-02", "C1-02i", "C2-00", "C2-01", "C2-02", "C2-03_C2-06", "C2-05", "C3-00", "C3-01", "C5-00", "C5-01", "C5-03", "C6-00", "C6-01", "C7-00_1", "C7-00", "E5-00", "E50", "E51", "E52", "E55", "E6-00", "E60", "E61", "E61i", "E62", "E63", "E65", "E66", "E7-00", "E70", "E71", "E71x", "E72", "E73", "E75", "E90", "N70", "N71", "N72", "N73", "N75", "N76", "N77", "N78", "N79", "N8-00", "N80", "N81", "N82", "N85", "N86_8MP", "N9", "N900", "N92", "N93", "N93i", "N95", "N95_8GB", "N96", "N97", "N97_mini", "Oro", "T7-00", "X2-00", "X2-01", "X2-02", "X2-05", "X3", "X3-02", "X5-00", "X5-01", "X6", "X7-00", "Const_T"}
      for k, v in pairs(devices) do
        local devicedownload = "http://store.ovi.com/content/"..number.."/Download?terminalId="..v.."&reload=1&fragment=1"
        local deviceurl = "http://store.ovi.com/content/"..number.."?terminalId="..v.."&reload=1&fragment=1"
        check(deviceurl)
      end
    end
    if string.match(url, "[^0-9]"..item_value.."[0-9]") then
      html = read_file(file)
      for newurl in string.gmatch(html, 'src="(https?://[^"]+)"') do
        if string.match(newurl, "https?://[a-z]%.[a-z]%.ovi%.com/[a-z]/[a-z]/store/") then
          check(newurl)
        end 
      end
    end
    if string.match(url, "[a-z]%.[a-z]%.ovi%.com/[a-z]/[a-z]/store/[0-9]+/[^%?]+%?") then
      local newurl = string.match(url, "(https?://[^/]+/[a-z]/[a-z]/store/[0-9]+/[^%?]+)%?")
      check(newurl)
    end
  end
  
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  last_http_statcode = status_code
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if (status_code >= 200 and status_code <= 399) or status_code == 403 then
    if string.match(url["url"], "https://") then
      local newurl = string.gsub(url["url"], "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url["url"]] = true
    end
  end
  
  if (string.match(url["url"], "https?://store%.ovi%.com/content/"..item_value.."[0-9]/Download%?terminalId=") or string.match(url["url"], "https?://[a-z]%.ovi%.com/")) and downloadsize[http_stat["orig_file_size"]] == true then
    io.stdout:write("\nOld.\n")
    io.stdout:flush()
    return wget.actions.EXIT
  elseif (string.match(url["url"], "https?://store%.ovi%.com/content/"..item_value.."[0-9]/Download%?terminalId=") or string.match(url["url"], "https?://[a-z]%.ovi%.com/")) and downloadsize[http_stat["orig_file_size"]] == false then
    io.stdout:write("\nNew.\n")
    io.stdout:flush()
    downloadsize[http_stat["orig_file_size"]] = true
    return wget.actions.NOTHING
  elseif string.match(url["url"], "https?://store%.ovi%.com/content/[0-9]+/Download") and status_code == 500 then
    return wget.actions.ABORT
  elseif string.match(url["url"], "https?://[a-z]%.[a-z]%.ovi%.com/") and status_code == 400 then
    return wget.actions.EXIT
  elseif string.match(url["url"], "https?://[a-z]%.ovi%.com/") and status_code == 400 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.EXIT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 1")

    tries = tries + 1

    if tries >= 20 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 10 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(500, 5000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
