
require('dumper')

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

function remind:initialize(selene)
	Plugin.initialize(self,selene)
	self:load()
end

function remind:add(nick,time,text,channel)
    self.reminds = self.reminds or {}
    table.insert(self.reminds, {channel = channel, nick = nick, time = os.time() + time, text = text})
end

function remind:check()
    for i,v in ipairs(self.reminds or {}) do
        if v.time < os.time() then
            self.selene:sendChat(v.channel, self.selene.ircColor(v.nick,2) .. ", you asked me to remind you: " .. self.selene.ircColor(v.text,4))
            table.remove(self.reminds, i)
        end
    end
end

function remind:load()
	local dir = self.selene:getSaveDir("remind")
	local fn,err = loadfile(dir .. "/remind.lua")
	if fn then
		self.reminds = fn()
	else
		self.selene:print(err)
	end
end

function remind:save()
	local dir = self.selene:getSaveDir("remind")
	local f,err = io.open(dir .. "/remind.lua","w")
	if f then
		f:write(DataDumper(self.reminds or {}))
		f:close()
	else
		self.selene:error(err)
	end
end

function remind:OnShutdown()
	self:save()
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
