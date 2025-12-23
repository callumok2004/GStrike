hook.Add("Initialize", "GStrike.PerformanceInitialize", function()
	hook.Remove("PlayerTick", "TickWidgets")
	hook.Remove("RenderScreenspaceEffects", "RenderColorModify")
	hook.Remove("RenderScreenspaceEffects", "RenderBloom")
	hook.Remove("RenderScreenspaceEffects", "RenderToyTown")
	hook.Remove("RenderScreenspaceEffects", "RenderTexturize")
	hook.Remove("RenderScreenspaceEffects", "RenderSunbeams")
	hook.Remove("RenderScreenspaceEffects", "RenderSobel")
	hook.Remove("RenderScreenspaceEffects", "RenderSharpen")
	hook.Remove("RenderScreenspaceEffects", "RenderMaterialOverlay")
	hook.Remove("RenderScreenspaceEffects", "RenderMotionBlur")
	hook.Remove("RenderScene", "RenderStereoscopy")
	hook.Remove("RenderScene", "RenderSuperDoF")
	hook.Remove("GUIMousePressed", "SuperDOFMouseDown")
	hook.Remove("GUIMouseReleased", "SuperDOFMouseUp")
	hook.Remove("PreventScreenClicks", "SuperDOFPreventClicks")
	hook.Remove("PostRender", "RenderFrameBlend")
	hook.Remove("PreRender", "PreRenderFrameBlend")
	hook.Remove("Think", "DOFThink")
	hook.Remove("RenderScreenspaceEffects", "RenderBokeh")
	hook.Remove("NeedsDepthPass", "NeedsDepthPass_Bokeh")
	hook.Remove("PostDrawEffects", "RenderWidgets")
	hook.Remove("Initialize", "GStrike.PerformanceInitialize")

	if CLIENT then
		concommand.Remove("lua_find_cl")
		concommand.Remove("lua_findhooks_cl")

		local ply
		local localPlayer = LocalPlayer

		function LocalPlayer()
			ply = localPlayer()

			if ply and ply:IsValid() then
				_G.LocalPlayer = function() return ply end
			end

			return ply
		end

		local tonumber = tonumber
		local COLOR = FindMetaTable("Color")
		function Color(r, g, b, a)
			return setmetatable({
				r = tonumber(r) or 255,
				g = tonumber(g) or 255,
				b = tonumber(b) or 255,
				a = tonumber(a) or 255
			}, COLOR)
		end

		local _ScrW, _ScrH = ScrW, ScrH
		local ScrWV, ScrHV = _ScrW(), _ScrH()

		function ScrW() return ScrWV end
		function ScrH() return ScrHV end

		hook.Add("InitPostEntity", "GStrike.PerformanceInitPostEntity", function()
			ScrWV, ScrHV = _ScrW(), _ScrH()
		end)

		hook.Add("OnScreenSizeChanged", "GStrike.PerformanceOnScreenSizeChanged", function()
			ScrWV, ScrHV = _ScrW(), _ScrH()
		end)
	end

	if SERVER then
		local meta = FindMetaTable( "Player" )
		CUserID = CUserID or meta.UserID
		CSteamID64 = CSteamID64 or meta.SteamID64
		CSteamID = CSteamID or meta.SteamID
		local UserID, SteamID64, SteamID = CUserID, CSteamID64, CSteamID

		function meta:UserID() return self.__UserID or UserID( self ) end
		function meta:SteamID64() return self.__SteamID64 or SteamID64( self ) end
		function meta:SteamID() return self.__SteamID or SteamID( self ) end

		local function Cache( ply )
			ply.__UserID = UserID( ply )
			ply.__SteamID64 = SteamID64( ply )
			ply.__SteamID = SteamID( ply )
		end
		hook.Add("PlayerInitialSpawn", "CacheUserID", Cache, HOOK_MONITOR_HIGH )
		hook.Add("PlayerAuthed", "CacheUserID", Cache, HOOK_MONITOR_HIGH )
	end
end)

function IsValid( object )
	if (object == nil) then return false end
	if (object == false) then return false end
	if (object == NULL) then return false end

	local func = object.IsValid
	if (func == nil) then
		return false
	end

	return func( object )
end

local mmin, mmax = math.min, math.max
function math.Clamp( _in, low, high )
	return mmin( mmax( _in, low ), high )
end

local rand = math.random
function table.Random(t)
	return t[rand(1, #t)]
end

local M_Weapon = FindMetaTable("Weapon")
local M_Entity = FindMetaTable("Entity")
local M_Player = FindMetaTable("Player")
local E_GetTable = M_Entity.GetTable
local E_GetOwner = M_Entity.GetOwner
local val, wt, val2, wt2

function M_Weapon:__index(key)
	val = M_Weapon[key]
	if val ~= nil then return val end

	val = M_Entity[key]
	if val ~= nil then return val end

	if key == "Owner" then return E_GetOwner(self) end

	wt = E_GetTable(self)
	if wt then return wt[key] end
end

function M_Player:__index(key)
	val2 = M_Player[key]
	if val2 ~= nil then return val2 end

	val2 = M_Entity[key]
	if val2 ~= nil then return val2 end

	wt2 = E_GetTable(self)
	if wt2 then return wt2[key] end
end

local E_GetClass = M_Entity.GetClass
function M_Entity:GetClass()
	if self == NULL then return E_GetClass(self) end

	local Cached = self.z_Class
	if Cached then return Cached end

	local Class = E_GetClass(self)
	self.z_Class = Class
	return Class
end