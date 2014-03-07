
local class = require('middleclass')

Plugin = class("Plugin")

Plugin.priority = 0

function Plugin:initialize(selene)
    self.selene = selene
end

function Plugin:OnShutdown() end
function Plugin:OnTick() end

for i,v in ipairs(Selene.hooks) do
    Plugin[v] = function() end
end
