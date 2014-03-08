require('irc')
require('lfs')
local colors = require('ansicolors')

local class = require('middleclass')

Selene = class("Selene")

Selene.static.hooks = { "OnRaw", "OnDisconnect", "OnChat", "OnNotice", "OnJoin", "OnPart", "OnQuit",
                        "NickChange", "NameList", "OnTopic", "OnTopicInfo", "OnKick", "OnUserMode",
                        "OnChannelMode", "OnModeChange"}


function Selene:initialize(conf)
    self.running = true
    local s = conf.server
    assert(s, "No server given")
    assert(s.host, "No server address given")
    s.port = s.port or 6667
	self.answersTo = conf.answersTo or {}
	table.insert(self.answersTo, conf.nick or "Selene")
    self.irc = irc.new{ nick = conf.nick or "Selene", username = "Selene", realname = "Selene" }

    --load plugins 
    -- built in

    require('plugin')
    local defs = {}
    for file in lfs.dir("./plugins") do -- TODO this might cause problems
        if file == "." or file == ".." then
        else
            local p,err = loadfile("./plugins/" .. file)
            if p then
                self:print("%{green}Loaded " .. file)
                table.insert(defs, p())
            else
                self:error("Error loading " .. file .. " : " .. err)
            end
        end

    end
    -- TODO load plugins from user dir
    self.plugins = {}
    for i,v in ipairs(defs) do
        table.insert(self.plugins, v(self))
    end
    -- do hooks
    local function makeHook(selene, hookName)
        selene[hookName] = function(self,...)
            table.sort(self.plugins, function(a,b)
                return a.priority < b.priority
            end)
            for i,v in ipairs(self.plugins or {}) do
                v[hookName](v,...)
            end
        end
        return function(...)
            selene[hookName](selene,...)
        end
    end
    for i,v in ipairs(Selene.hooks) do
        self.irc:hook(v, makeHook(self,v))
    end
    self.irc:hook("OnRaw", function(message) self:print("%{blue}" .. message) end)
    
    -- now connect and join
    self.irc:connect(s)
    for i,v in ipairs(s.channels or {}) do
        self:print("%{green}Joining " .. v)
        self.irc:join(v)
    end
end

function Selene:sendChat(target, message)
    self.irc:sendChat(target,message)
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function Selene:error(message)
    print(colors("%{red}" .. message))
end

function Selene:print(message)
    print(colors(message))
end

function Selene:isDirect(message)
    message = trim(message)
	local patterns = {}
	for i,v in ipairs(self.answersTo) do
		v = v:lower()
		table.insert(patterns, "^" .. v .. "%W")
		table.insert(patterns, "%s" .. v .. "$")
	end
	local lowerMessage = message:lower()
	for i,v in ipairs(patterns) do
		if string.match(lowerMessage, v) then
			if v:sub(1,1) == "^" then
				return true, trim(string.sub(message, v:len() - 1))
			else
				return true, trim(string.sub(message, 1, message:len() - (v:len() - 2)))
			end
		end
	end
end

function Selene.ircColor(...)
	return irc.color(...)
end

function Selene:formatTime(t)
    t = math.floor(t)
    local days = math.floor(t / 86400)
    t = t - days * 86400
    local hours = math.floor(t / 3600)
    t = t - hours * 3600
    local minutes = math.floor(t / 60)
    t = t - minutes * 60
    local seconds = t
    local s = ""
    if days > 0 then
        s = s .. days .. " days"
    end
    if hours > 0 then
        if s:len() > 0 then
            if minutes == 0 and seconds == 0 then
                s = s .. " and "
            else
                s = s .. ", "
            end
        end
        s = s .. hours .. " hours"
    end
    if minutes > 0 then
        if s:len() > 0 then
            if seconds == 0 then
                s = s .. " and "
            else
                s = s .. ", "
            end
        end
        s = s .. minutes .. " minutes"
    end
    if seconds > 0 then
        if s:len() > 0 then
            s = s .. " and " 
        end
        s = s .. seconds .. " seconds"
    end
    return s
end

function Selene:quit()
    self:print("%{green}Shutting down!")
    for i,v in ipairs(self.plugins) do
        v:OnShutdown()
    end
    self.running = false
end

function Selene:getSaveDir(name)
    local home = os.getenv("HOME")
    local dir = home .. "/.config/selene/" .. name
    lfs.mkdir(dir)
    return dir
end

function Selene:tick()
    for i,v in ipairs(self.plugins or {}) do
        v:OnTick()
    end
end

function Selene:run()
    local sleep = require("socket").sleep
    self:print ("%{green}Running")
    while self.running do
        self.irc:think()
        self:tick()
        sleep(0.5)
    end
end
