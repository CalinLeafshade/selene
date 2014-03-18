-- Plugin to catch all direct but uncaught messages

local huh = Plugin:subclass("huh")
huh.priority = math.huge
local huhs = {"Huh?", "What?", "I don't understand.", "You trippin'?" }

function huh:OnChat(user,channel,message)
    if self.selene:isDirect(message) then
        self.selene:sendChat(channel, user.nick .. ", " .. huhs[math.random(#huhs)])
        return true 
    end
end

return huh
