
local factoids = Plugin:subclass("factoids")


function factoids:initialize(...)
    Plugin.initialize(self,...)
    self.factoids = {}
    self:load()
    self.priority = 9999
end

function factoids:load()
    local f,err = loadfile(self.selene:getSaveDir("factoids") .. "/factoids.lua")
    if f then
        self.factoids = f() or {}
        local count = 0
        for i,v in pairs(self.factoids) do
            count = count + 1
        end
        self.selene:print("%{blue}Loaded " .. count .. " factoids from disk")
    else
        self.selene:error(err)
    end
end

function factoids:add(key,content,by)
    if self.factoids[key:lower()] then
        return false
    end
    local f = {
        content = content,
        nick = by,
        when = os.time(),
        key = key
    }
    self.factoids[key:lower()] = f
    self:save()
    return true
end

function factoids:forget(key)
    key = key:lower()
    if self.factoids[key] then
        self.factoids[key] = nil
        self:save()
        return true
    end
end

function factoids:save()
    local f,err = io.open(self.selene:getSaveDir("factoids") .. "/factoids.lua", "w")
    if f then
        local data = DataDumper(self.factoids)
        f:write(data)
        f:close()
    else
        self.selene:error(err)
    end
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function factoids:OnChat(user,channel,message)
    local direct, mess = self.selene:isDirect(message)
    if direct then
        local noun = mess:match("forget%s(.+)")
        if noun then
            if self:forget(noun) then
                self.selene:sendChat(channel, noun .. " forgotten.")
            else
                self.selene:sendChat(channel, "That's not in the dictionary.")
            end
            return true
        elseif self.factoids[mess:lower()] then
            local f = self.factoids[mess:lower()]
            if f.content:match("<reply>") then
                local content = trim(f.content:gsub("<reply>",""))
                content = content:gsub("%$who", user.nick)
                self.selene:sendChat(channel, content)
            else
                local col = self.selene.ircColor
                local content = f.content:gsub("%$who", user.nick)
                self.selene:sendChat(channel, table.concat{col(user.nick, 2), ", ", f.key, " is ", content})
            end
            return true
        else
            local key,content = mess:match("^(.+)%sis%s(.+)$")
            if key and content then
                if self:add(key,content,user.nick) then
                    self.selene:sendChat(channel,"Ok, I've added that to the dictionary")
                else
                    self.selene:sendChat(channel,"That's already in the dictionary. Use 'forget' to remove it")
                end
                return true
            end
        end
    end
end

return factoids
