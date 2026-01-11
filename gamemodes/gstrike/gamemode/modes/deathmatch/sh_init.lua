print("Deathmatch Gamemode")

local Deathmatch = GStrike.BaseMode:New("Deathmatch")

Deathmatch:SetConfigKV("AllowTeamSwitch", true)
Deathmatch:SetConfigKV("MaxTeamSize", "10")

function Deathmatch:LoadCvars()

end