
local logDir = "/home/steve/public_html/selene/logs"

local logger = Plugin:subclass("logger")

function logger:initialize(selene)
    self.selene = selene
end

function logger:log(channel, text)
    lfs.mkdir(logDir .. "/" .. channel:sub(2))
    local file = logDir .. "/" .. channel:sub(2) .. "/" .. os.date("%d-%m-%y") .. ".log"
    local f,err = io.open(file,"a+")
    if f then
        f:write(os.date("%X") .. " " .. text .. "\n")
        f:close()
    else
        print(err)
    end
end

function logger:OnJoin(user, channel)
	self:log(channel, "* " .. user.nick .. " has joined the channel." 
end

function logger:OnChat(user,channel,message)
    self:log(channel, "<" .. user.nick .. "> " .. message)
end

return logger

