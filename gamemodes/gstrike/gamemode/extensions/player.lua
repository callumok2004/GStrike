local PLAYER = FindMetaTable("Player")

function meta:CheckCooldown(name, time) -- if not ply:CheckCooldown("something", time) then return end
	local Cooldowns = self.Cooldowns
	if not Cooldowns then
		Cooldowns = {}
		self.Cooldowns = Cooldowns
	end

	local Cooldown = Cooldowns[name]
	if not Cooldown then
		Cooldowns[name] = CurTime() + (time or 0)
		return true
	elseif Cooldown <= CurTime() then
		Cooldowns[name] = CurTime() + (time or 0)
		return true
	else
		return false
	end
end