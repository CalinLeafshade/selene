local class = require('middleclass')

local hi = class("hi", Plugin)

function hi:initialize(selene)
    self.selene = selene
end

function hi:OnChat(user,channel,message)
    local direct, mes = self.selene:isDirect(message)
    if direct then
        if mes:lower() == "hi" then
            print(table.inspect(self.selene.irc:whois(user.nick)))
            self.selene:sendChat(channel, "Hi " .. user.nick)
        end   
    end
end

return hi
