dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}

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
    if string.match(url, "[^0-9]"..item_value.."[0-9][^0-9]") 
    and not string.match(url, "https?://store%.ovi%.com/content/"..item_value.."[0-9]/.*applications%?categoryId=[0-9]+") 
    and not string.match(url, "https?://store%.ovi%.com/content/"..item_value.."[0-9]/channel/channel/")
    and not string.match(url, "https?://store%.ovi%.com/content/.*clickSource=related")
    then
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
    if (downloaded[url] ~= true and addedtolist[url] ~= true) 
    and not string.match(url, "https?://store%.ovi%.com/content/"..item_value.."[0-9]/.*applications%?categoryId=[0-9]+") 
    and not string.match(url, "https?://store%.ovi%.com/content/"..item_value.."[0-9]/channel/channel/")
    and not string.match(url, "https?://store%.ovi%.com/content/.*clickSource=related")
    then
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

  if url_count > 1000 then
    io.stdout:write("This job appears to be stuck. Please report this job ID.  \n")
    io.stdout:write("Waiting 60 seconds and then abort.  \n")
    io.stdout:flush()
    os.execute("sleep 60")
    return wget.actions.ABORT
  end

  if (status_code >= 200 and status_code <= 399) then
    if string.match(url["url"], "https://") then
      local newurl = string.gsub(url["url"], "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url["url"]] = true
    end
  end
  
  -- if 500, app is not available in country
  if string.match(url["url"], "https?://store%.ovi%.com/content/[0-9]+/Download") and status_code == 500 then
    -- comment out abort. grab what we can first, then try to get it later
    -- return wget.actions.ABORT
    return wget.actions.EXIT
  elseif string.match(url["url"], "https?://[a-z]%.[a-z]%.ovi%.com/") and status_code == 400 then
    return wget.actions.EXIT
  elseif (string.match(url["url"], "https?://[a-z]%.ovi%.com/") or string.match(url["url"], "https?://qa%.p%.d.ovi%.com/")) and status_code == 400 then
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
    (status_code >= 400 and status_code ~= 404) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 5")

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
  -- local sleep_time = 0.1 * (math.random(500, 2000) / 1000.0)
  local sleep_time = 0.2

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
