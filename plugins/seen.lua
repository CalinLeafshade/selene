
local seen = Plugin:subclass("seen")

function seen:OnChat(user,channel,message)
    self.nicks = self.nicks or {}
    local direct, mess = self.selene:isDirect(message)
    if direct then
        local cmd,nick = mess:match("(%w+)%s(%w+)")
        if cmd and cmd:lower() == "seen" and nick then
            local time = self.nicks[nick:lower()]
            local col = self.selene.ircColor
            if time then
                self.selene:sendChat(channel, table.concat{col(user.nick,2), ", I last saw ", col(nick, 4), " ", self.selene:formatTime(os.difftime(os.time(), time[1])), " ago saying ", col(time[2],6)})
            else
                self.selene:sendChat(channel, table.concat{col(user.nick,2), ", I haven't seen ", col(nick,4)})
            end
            return true
        end
    end
    self:record(user.nick, message)
end

function seen:record(nick, saying)
    self.nicks[nick:lower()] = {os.time(),saying}
end

return seen
