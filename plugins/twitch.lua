local https = require("ssl.https")
local ltn12 = require('ltn12')

local twitch = Plugin:subclass("twitch")

function twitch:initialize(...)
    Plugin.initialize(self,...)
    self.subs = {}
    self.lastUpdate = os.time()
    self.updateFrequency = 3
    self:load()
    self:update(false)
end

function twitch:save()
    local f,err = io.open(self.selene:getSaveDir("twitch") .. "/twitch.lua", "w")
    local subs = {}
    for i,v in pairs(self.subs) do
        table.insert(subs, {user = i, channel = v.ircChannel})
    end
    local data = DataDumper(subs)
    if f then
        f:write(data)
        f:close()
    else
        self.selene:error(err)
    end
end

function twitch:load()
    local f,err = loadfile(self.selene:getSaveDir("twitch") .. "/twitch.lua")
    if f then
        local subs = f() or {}
        for i,v in ipairs(subs) do
            self.subs[v.user] = { ircChannel = v.channel }
        end
    else
        self.selene:error(err)
    end
end

function twitch:subscribe(twitchUser, channel)
    twitchUser = twitchUser:lower()
    if self.subs[twitchUser] then
        return false
    else
        self.subs[twitchUser] = 
        {
            ircChannel = channel
        }
        self:save()
        self:update(true)
        return true
    end
end

function twitch:unsubscribe(user)
    if self.subs[user:lower()] then
        self.subs[user:lower()] = nil
        self:save()
        return true
    end
end

function twitch:list(channel)
    local active = {}
    for i,v in pairs(self.subs) do
        if v.stream then
            table.insert(active, i)
        end
    end
    if #active == 0 then
        self.selene:sendChat(channel, "No one from the sublist is streaming")
    else
        self.selene:sendChat(channel, "The following people are streaming:")
        for i,v in ipairs(active) do
            self.selene:sendChat(channel, v .. ": http://www.twitch.tv/" .. v)
        end
    end
end

function twitch:update(loud)
    local co = self.co or coroutine.create(function(loud)
        local last
        while true do 
            local v
            last, v = next(self.subs, last)
            if last and v then
                local success, stream = pcall(function() return self:getStream(last) end)
		        if success then
			        if stream and not v.stream then
				        if loud then
					        self.selene:sendChat(v.ircChannel, i .. " has just started streaming on twitch.tv: http://www.twitch.tv/" .. i)
        				end
                    end
	    			v.stream = stream
		    	elseif not stream and v.stream then
			    	if loud then
				    	self.selene:sendChat(v.ircChannel, i .. " has stopped streaming.")
    				end
	    			v.stream = nil
		    	end
    		end
            loud = coroutine.yield()
        end
    end)
    coroutine.resume(co, loud)
    self.co = co
end

function twitch:OnTick()
    local t = os.difftime(os.time(), self.lastUpdate)
    if t > self.updateFrequency then
        self.lastUpdate = os.time()
        self:update(true)
    end
end

function twitch:OnChat(user,channel,message)
    local direct, mess = self.selene:isDirect(message)
    if direct then
        mess = mess:lower()
        caught = false
        if mess == "twitch" then
            self:list(channel)
            return true
        end
        words = {}
        string.gsub(mess, "(%a+)", function (w)
            table.insert(words, w)
        end)
        local cmd, arg = words[2], words[3]
        print(cmd, arg)
        if cmd == "sub" then
            if self:subscribe(arg,channel) then
                self.selene:sendChat(channel, "Ok, I'll notify you if they start streaming")
            else
                self.selene:sendChat(channel, "I am already monitoring their channel.")
            end
            return true
        elseif cmd == "unsub" then
            if self:unsubscribe(arg) then
                self.selene:sendChat(channel, "Successfully unsubscribed")
            else
                self.selene:sendChat(channel, "I am not monitoring their channel")
            end
            return true
        elseif cmd == "list" then
            local list = ""
            for i,v in pairs(self.subs) do
                if list:len() > 0 then
                    list = list .. ", "
                end
                list = list .. i
            end
            if list == "" then
                self.selene:sendChat(channel, "There is no one on the sublist")
            else
                self.selene:sendChat(channel, "This is the current sublist: " .. list)
            end
            return true
        elseif cmd == "status" then
			local success, stream = pcall(function() return self:getStream(arg) end)
			if success then
				if stream then
					self.selene:sendChat(channel, arg .. " is currently streaming: http://www.twitch.tv/" .. arg)
				else
					self.selene:sendChat(channel, arg .. " is not current streaming.")
				end
			else
				if stream then self.selene:error(stream) end
				self.selene:sendChat(channel, "Failed to get stream info.")
			end
            return true
        end
    end 
end

function twitch:getStream(user)
    local t = {}
    https.request{
        url = "https://api.twitch.tv/kraken/streams/" .. user, 
        sink = ltn12.sink.table(t)
    }
    local data = table.concat(t)
    decoded = json:decode(data)
    return decoded and decoded.stream
end

return twitch
