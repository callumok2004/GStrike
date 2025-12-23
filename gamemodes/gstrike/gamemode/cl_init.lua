include("shared.lua")


local root = GM.FolderName.."/gamemode/modules/"

local _, folders = file.Find(root.."*", "LUA")
for _, folder in SortedPairs(folders, true) do
   local files = file.Find(root .. folder .."/*.lua", "LUA")
   for _,File in SortedPairs(files,true) do
      if File:StartWith("sh_") or File:StartWith("cl_") then
         include(root.. folder .. "/" ..File)
      end
   end
end

function GM:Initialize()
   self.BaseClass:Initialize()
end

function GM:CleanUpMap()
   for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
      if IsValid(ent) and CORPSE.GetPlayerNick(ent, "") != "" then
         ent:SetNoDraw(true)
         ent:SetSolid(SOLID_NONE)
         ent:SetColor(Color(0,0,0,0))
         ent.NoTarget = true
      end
   end

   game.CleanUpMap()
end

function GM:ShouldDrawLocalPlayer(ply) return false end

local view = {origin = vector_origin, angles = angle_zero, fov=0}
function GM:CalcView( ply, origin, angles, fov )
   -- view.origin = origin
   -- view.angles = angles
   -- view.fov    = fov

   -- if ply:Team() == TEAM_SPEC and ply:GetObserverMode() == OBS_MODE_IN_EYE then
   --    local tgt = ply:GetObserverTarget()
   --    if IsValid(tgt) and (not tgt:IsPlayer()) then
   --       local eyes = tgt:LookupAttachment("eyes") or 0
   --       eyes = tgt:GetAttachment(eyes)
   --       if eyes then
   --          view.origin = eyes.Pos
   --          view.angles = eyes.Ang
   --       end
   --    end
   -- end


   -- local wep = ply:GetActiveWeapon()
   -- if IsValid(wep) then
   --    local func = wep.CalcView
   --    if func then
   --       view.origin, view.angles, view.fov = func( wep, ply, origin*1, angles*1, fov )
   --    end
   -- end

   -- return view
end

function GM:AddDeathNotice() end
function GM:DrawDeathNotice() end
