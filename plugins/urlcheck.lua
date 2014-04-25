
local http = require("socket.http")
local ltn12 = require('ltn12')

local url = Plugin:subclass("url")
url.priority = -math.huge
function url:isHTML(u)
    r,c,h = http.request{
        method = "HEAD",
        url = u,
        timeout = 5
    }
    local t = h["content-type"] or h["Content-Type"]
    return t and t:match("text/html")
end

function unesc(str)
    --str = string.gsub(str, "&#%d+;", function(d) return string.char(tonumber(d:sub(3,-2))) end)
    str = string.gsub(str, "&amp;", "&")
    str = string.gsub(str, "&bull;", "")
    str = string.gsub(str, "&lt;", "<")
    str = string.gsub(str, "&gt;", ">")
	str = string.gsub(str, "&%a+;", "") -- strip all other escape sequences
    return str
end

function url_decode(str)
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)",function(h) return string.char(tonumber(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end

function url:checkURL(u)
    if self:isHTML(u) then
        local t = {}
        http.request{ 
            url = u, 
            sink = ltn12.sink.table(t)
        }
        local data = table.concat(t)
        return string.match(data, "<title>(.+)</title>")
    end
end

function url:OnChat(user,channel,message)
    for u in message:gmatch("https?://%S*") do
        u = string.gsub(u,"https://", "http://")
        local t = self:checkURL(u)
        if t then
			t = t:gsub("%c", ""):trim() -- strip newlines and other control chars
            self.selene:sendChat(channel, unesc(t))
        end
    end
end

return url
