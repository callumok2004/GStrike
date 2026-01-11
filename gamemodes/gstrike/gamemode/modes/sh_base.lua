GStrike.Modes = GStrike.Modes or {}
local Modes = GStrike.Modes

local BaseMode = {}
setmetatable(BaseMode, {__index = BaseMode})

-- this is probably going to change.. a lot

BaseMode.Config = {
	RoundBased = false,
	AllowTeamSwitch = false,
	MaxTeamSize = 0
}

function BaseMode:New(name)
	if Modes[name] then return Modes[name] end
	local obj = setmetatable({}, {__index = self})
	Modes[name] = obj
	return obj
end

function BaseMode:SetConfigKV(key, value)
	self.Config[key] = value
	return self
end

function BaseMode:LoadCvars() return self end

GStrike.BaseMode = BaseMode