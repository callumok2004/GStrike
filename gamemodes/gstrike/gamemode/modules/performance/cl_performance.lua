if GStrike_OptLoaded then return end -- Don't want to nest functions to deep if we keep reloading the file
GStrike_OptLoaded = true

-- Font Cache
local SetFont = surface.SetFont
local GetTextSize = surface.GetTextSize
local font = "TargetID"

local cache = setmetatable({}, {
	__mode = "k"
})

timer.Create("surface.ClearFontCache", 1800, 0, function()
	surface.ClearFontCache()
end)

function surface.ClearFontCache()
	for key in pairs(cache) do cache[key] = nil end
end

function surface.SetFont(_font)
	font = _font

	return SetFont(_font)
end

function surface.GetTextSize(text)
	if text == nil or text == "" then return 1, 1 end

	if not cache[font] then
		cache[font] = {}
	end

	if not cache[font][text] then
		local w, h = GetTextSize(text)

		cache[font][text] = {
			w = w,
			h = h
		}

		return w, h
	end

	return cache[font][text].w, cache[font][text].h
end


-- Draw Caches, noticably faster
local surface = surface
local Color = Color
local color_white = color_white

local TEXT_ALIGN_CENTER	= 1
local TEXT_ALIGN_RIGHT = 2
local TEXT_ALIGN_BOTTOM	= 4

local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextPos = surface.SetTextPos
local surface_SetTextColor = surface.SetTextColor
local surface_DrawText = surface.DrawText
local string_sub = string.sub
local math_ceil = math.ceil

GStrike_CachedFonts = {}
function draw.GetFontHeight(font)
	if GStrike_CachedFonts[font] then
		return GStrike_CachedFonts[font]
	end

	surface_SetFont(font)
	local _, h = surface_GetTextSize("W")
	GStrike_CachedFonts[font] = h

	return h
end

function draw.SimpleText(text, font, x, y, color, xalign, yalign)
	surface_SetFont(font or "DermaDefault")

	if xalign == TEXT_ALIGN_CENTER then
		local w, _ = surface_GetTextSize(text)
		x = x - w / 2
	elseif xalign == TEXT_ALIGN_RIGHT then
		local w, _ = surface_GetTextSize(text)
		x = x - w
	end

	if yalign == TEXT_ALIGN_CENTER then
		local h = draw.GetFontHeight(font)
		y = y - h / 2
	elseif yalign == TEXT_ALIGN_BOTTOM then
		local h = draw.GetFontHeight(font)
		y = y - h
	end

	surface_SetTextPos(x, y)
	if color then
		surface_SetTextColor(color.r, color.g, color.b, color.a)
	else
		surface_SetTextColor(255, 255, 255, 255)
	end
	surface_DrawText(text)
end

function draw.DrawText(text, font, x, y, color, xalign)
	local curX = x
	local curY = y
	local curString = ""
	text = tostring(text)

	local lineHeight = draw.GetFontHeight(font or "DermaDefault")

	for i=1, #text do
		local ch = string_sub(text, i, i)
		if ch == "\n" then
			if #curString > 0 then
				draw.SimpleText(curString, font, curX, curY, color, xalign)
			end

			curY = curY + lineHeight -- / 2
			curX = x
			curString = ""
		elseif ch == "\t" then
			if #curString > 0 then
				draw.SimpleText(curString, font, curX, curY, color, xalign)
			end
			local tmpSizeX, _ =  surface_GetTextSize(curString)
			curX = math_ceil( (curX + tmpSizeX) / 50 ) * 50
			curString = ""
		else
			curString = curString .. ch
		end
	end
	if #curString > 0 then
		draw.SimpleText(curString, font, curX, curY, color, xalign)
	end
end

function draw.Text(tab)
	local text = tostring(tab.text or "")
	local font = tostring(tab.font or "DermaDefault")
	local x = tab.pos[1] or 0
	local y = tab.pos[2] or 0
	local xalign = tab.xalign
	local yalign = tab.yalign

	surface_SetFont(font)

	local w, h = surface_GetTextSize(text)

	if xalign == TEXT_ALIGN_CENTER then
		x = x - w / 2
	elseif xalign == TEXT_ALIGN_RIGHT then
		x = x - w
	end

	if yalign == TEXT_ALIGN_CENTER then
		local h = draw.GetFontHeight(font)
		y = y - h / 2
	end

	surface_SetTextPos(x, y)

	if tab.color then
		surface_SetTextColor(tab.color)
	else
		surface_SetTextColor(255, 255, 255, 255)
	end

	surface_DrawText(text)

	return w, h
end

function draw.TextShadow(tab, distance, alpha)
	alpha = alpha or 200

	local color = tab.color
	local pos 	= tab.pos
	tab.color = Color(0, 0, 0, alpha)
	tab.pos = {pos[1] + distance, pos[2] + distance}

	local w, h = draw.Text(tab)

	tab.color = color
	tab.pos = pos

	draw.Text(tab)

	return w, h
end

function draw.SimpleTextOutlined(text, font, x, y, colour, xalign, yalign, outlinewidth, outlinecolor)
	local steps = (outlinewidth*2) / 3
	if steps < 1 then steps = 1 end

	for _x=-outlinewidth, outlinewidth, steps do
		for _y=-outlinewidth, outlinewidth, steps do
			draw.SimpleText(text, font, x + _x, y + _y, outlinecolor, xalign, yalign)
		end
	end

	draw.SimpleText(text, font, x, y, colour, xalign, yalign)
end

--
-- Panel index accessor tests
--
local g_PanelsTables = {}

local meta = FindMetaTable( "Panel" )

-- TODO: Include cached getskin in final ps outside of debug!
-- garry, why? https://i.imgur.com/3DeX4bM.png
meta.oldGetSkin = meta.oldGetSkin or meta.GetSkin
local skinCache = {}
function meta:GetSkin( ... )
	local cache = skinCache[self]
	if cache then return cache end

	local skin = self:oldGetSkin( ... )
	skinCache[self] = skin
	return skin
end

local GetTable = meta.GetTable

function meta:__index( key )
	--
	-- Panel-specialized values
	--
	if ( key == "x" or key == "X" ) then
		local x = meta.GetPos( self )
		return x
	elseif ( key == "y" or key == "Y" ) then
		local _, y = meta.GetPos( self )
		return y
	end

	--
	-- Search the panel table
	--
	local pnlTable = g_PanelsTables[self]

	if ( !pnlTable ) then
		pnlTable = GetTable( self )

		if ( !pnlTable ) then
			-- If table isn't yet installed, look in the metatable
			return meta[key]
		end

		g_PanelsTables[self] = pnlTable
	end

	local value = pnlTable[key]

	-- Look in the table
	if ( value != nil ) then
		return value
	end

	return meta[key]
end

timer.Create("ClearPanelCache", 5, 0, function()
	for k, v in pairs( g_PanelsTables ) do
		if ( !IsValid( k ) ) then
			g_PanelsTables[k] = nil
		end
	end
end)