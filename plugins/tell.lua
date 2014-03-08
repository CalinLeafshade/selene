

require('dumper')

local tell = Plugin:subclass("tell")

function tell:initialize(selene)
    Plugin.initialize(self,selene)
    self.tells = {}
    self:load()
end

function tell:add(from,to,message)
    table.insert(self.tells, {from = from, to = to, message = message, time = os.time()})
end

function tell:tell(tell,channel) -- lol
	local col = self.selene.ircColor
	local time = self.selene:formatTime(os.difftime(os.time(), tell.time))
	local s = table.concat{ col(tell.to,2), ", ", col(tell.from,4), " left this message for you ",  col(time,3), " ago, ", col(tell.message,6)}
	print(s)
    self.selene:sendChat(channel, s)
end

function tell:check(nick,channel)
    for i,v in ipairs(self.tells) do
        if v.to:lower() == nick:lower() then
            self:tell(v,channel)
            table.remove(self.tells, i)
        end
    end
end

function tell:load()
    local f,err = loadfile(self.selene:getSaveDir("tells") .. "/tells.lua")
    if f then
        self.tells = f()
        self.selene:print("%{blue}Loaded " .. #self.tells .. " tells from disk.")
    else
        self.selene:error(err)
    end
end

function tell:save()
    self.selene:print("%{green} Saving tells")
    local data = DataDumper(self.tells)
    local f,err = io.open(self.selene:getSaveDir("tells") .. "/tells.lua","w")
    if f then
        f:write(data)
        f:close()
    else
        self.selene:error(err)
    end
end

function tell:OnShutdown()
    self:save()
end

function tell:OnChat(user,channel,message)
    self:check(user.nick,channel)
    local direct, mess = self.selene:isDirect(message)
    if direct and mess:lower():match("tell%s%w+%s+[%w+%s*]+") then
        local to = mess:match("[Tt][Ee][Ll][Ll]%s%w+"):sub(6)
        local text = mess:sub(6 + to:len() + 1)
        self:add(user.nick, to, text)
        self.selene:sendChat(channel, "Ok " .. user.nick .. ", I'll tell " .. to .. " that next time I see them.")
    end
end

return tell
