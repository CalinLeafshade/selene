
local epithet = Plugin:subclass("epithet")

local adjectives = {"Inconceivable", "Unbelievable", "Shocking", "Bamboozling", "Confoundable", "Stunning", "Irreconcilable" }


local function aoran(word)
    local c = word:sub(1,1):lower()
    return (c == "a" or c == "e" or c == "i" or c == "o" or c == "u") and "an" or "a"
end

function epithet:check(user,channel,message)
    for i,v in ipairs(self.epithets or {}) do
        if message:match(v) then
            local adj = adjectives[math.random(#adjectives)]
            if math.random() > 0.5 then
                self.selene:sendChat(channel, user.nick .. " is such " .. aoran(adj) .. " " .. adj .. " racist")
            else
                self.selene:sendChat(channel, "I never knew you were such " .. aoran(adj) .. " " .. adj .. " racist, " .. user.nick)
            end
            return
        end
    end
end

function epithet:add(epi)
    self.epithets = self.epithets or {}
    table.insert(self.epithets, epi)
end

function epithet:OnChat(user,channel,message)
    self:check(user,channel,message)
    local direct, mess =  self.selene:isDirect(message)
    if direct and mess:lower():match("^epithet") then
        local u = self.selene.irc:whois(user.nick)
        local allowed = false
        for i,v in ipairs(u.channels) do
            if v:match("&" .. channel) or v:match("@" .. channel) then
                allowed = true
            end
        end
        if allowed then
            self:add(mess:sub(8))
        else
            self.selene:sendChat(channel, "You dont have the privilege for that")
        end
    end
end

return epithet
