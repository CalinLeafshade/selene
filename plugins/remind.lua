
local remind = Plugin:subclass("remind")

local secondsIn = 
{
    seconds = 1,
    minutes = 60,
    hours = 3600,
    days = 86400,
    months = 2419200,
    years = 31536000,
    decades = 315360000
}

function remind:add(nick,time,text,channel)
    self.reminds = self.reminds or {}
    table.insert(self.reminds, {channel = channel, nick = nick, time = os.time() + time, text = text})
end

function remind:check()
    for i,v in ipairs(self.reminds or {}) do
        if v.time < os.time() then
            self.selene:sendChat(v.channel, v.nick .. ", you asked me to remind you: " .. v.text)
            table.remove(self.reminds, i)
        end
    end
end

function remind:OnTick()
    self:check()
end

function remind:OnChat(user,channel,message)
    local direct, mess = self.selene:isDirect(message)
    if direct then
        local cmd, nick, count, scale, text = mess:match("^(remind)%s(%a+)%sin%s(%d*)%s(%a+)%s([%w%s]+)")
        if cmd == "remind" then
            if not (nick and count and scale and text) or not tonumber(count) then
                self.selene:sendChat(channel, "Malformed request, pal.")
                return
            end
            local s = scale
            scale = scale:lower()
            scale = secondsIn[scale] or secondsIn[scale .. "s"]
            if not scale then
                self.selene:sendChat(channel, "I dont understand" ..  s)
                return
            end
            local time = scale * tonumber(count)
            if nick == "me" then nick = user.nick end
            self:add(nick, time, text, channel)
            self.selene:sendChat(channel, "Ok, i'll do that")
        end
    end
end

return remind
