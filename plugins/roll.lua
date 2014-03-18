
local roll = Plugin:subclass("roll")

function roll:OnChat(user,channel,message)
	local direct, mess = self.selene:isDirect(message)
	if direct then
		local cmd, count, size = string.match(mess:lower(), "^(roll)%s(%d+)d(%d+)$")
		if cmd == "roll" then
			count = tonumber(count)
			size = tonumber(size)
			if count and size then
				local col = self.selene.ircColor
				if count < 1 then
					self.selene:sendChat(channel,col("You must roll at least 1 dice", 4))
					return
				elseif count > 100 then
					self.selene:sendChat(channel,col("You can't roll more than 100 dice.", 4))
					return
				elseif size < 3 then
					self.selene:sendChat(channel, col("A " .. size .. " sided dice?", 4))
					return
				elseif size > 64 then 
					self.selene:sendChat(channel, col("Your dice had too many sides", 4))
					return
				end
				local rolls, total = self:roll(count, size)
				self.selene:sendChat(channel, col(user.nick, 2) .. ", you rolled " .. col(total, 4) .. col(" { " .. table.concat(rolls, ", ") .. " }", 6))
			else
				self.selene:sendChat(channel, col("Malformed request, pal", 4))
			end
            return true
		end
	end
end

function roll:roll(count, size)
	local rolls = {}
	local total = 0
	for i=1,count do
		local r = math.random(1,size)
		table.insert(rolls, r)
		total = total + r
	end
	return rolls, total
end

return roll
	
