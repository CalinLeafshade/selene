
local class  = require('middleclass')
local http = require("socket.http")
local ltn12 = require('ltn12')

local url = class("url", Plugin)

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
    str = string.gsub(str, "&#%d+;", function(d) return string.char(tonumber(d:sub(3,-2))) end)
    str = string.gsub(str, "&amp;", "&")
    str = string.gsub(str, "&lt;", "<")
    str = string.gsub(str, "&gt;", ">")
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
        local t = string.match(data, "<title>.+</title>")
        if t then return t:sub(8,-9) end
    end
end

function url:OnChat(user,channel,message)
    for u in message:gmatch("http://%S*") do
        local t = self:checkURL(u)
        if t then
            self.selene:sendChat(channel, unesc(t))
        end
    end
end

return url
