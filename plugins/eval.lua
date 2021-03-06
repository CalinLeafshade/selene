
local eval = Plugin:subclass("eval")

local disallowed = {"for", "while", "repeat"}

function eval:OnChat(user,channel,message)
    local direct, mess = self.selene:isDirect(message)
    if direct and mess:lower():sub(1,4) == "eval" then
        local fn = "do _ENV = {math = math, string = string} return " .. mess:sub(5) .. " end"
        for i,v in ipairs(disallowed) do
            if fn:match(v) then
                self.selene:sendChat(channel, "Sorry " .. user.nick .. ". Loops arent allowed")
                return true
            end
        end
        local fn, err = loadstring(fn)
        if fn then
            local ok, val = pcall(fn)
            if ok then
				val = tostring(val)
                self.selene:sendChat(channel, "The answer is: " .. self.selene.ircColor(val,2))
            else
                self.selene:sendChat(channel, "There was an error running your expression")
            end
        else
            self.selene:sendChat(channel, "There was an error compiling your expression")
        end
        return true

    end 
end

return eval
