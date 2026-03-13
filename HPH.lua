-- SessionHPH: Honor Per Hour - Session Tracker
-- Single-file addon, no libraries.

local sessionHonor = 0
local sessionStart = GetTime()
local honorLog     = {}   -- {t=timestamp, amount=n} for past-hour window
local lastUpdate   = 0
local lastTick     = 0

if not SessionHPH_db then
	SessionHPH_db = {}
end

-- Lua 5.0: no string.match, use string.find captures
local function matchOne(s, pat)
	local _, _, cap = string.find(s, pat)
	return cap
end

-- Format number with thousands separator (no string.reverse in Lua 5.0)
local function formatHonor(n)
	local s = tostring(math.floor(n))
	local len = string.len(s)
	if len <= 3 then return s end
	local out = ""
	local count = 0
	for i = len, 1, -1 do
		if count == 3 then
			out = "," .. out
			count = 0
		end
		out = string.sub(s, i, i) .. out
		count = count + 1
	end
	return out
end

-- Central function called whenever honor is gained
local function addHonor(honor)
	if not honor or honor <= 0 then return end
	local t = GetTime()
	sessionHonor = sessionHonor + honor
	table.insert(honorLog, {t = t, amount = honor})
end

-- Event frame
local EventFrame = CreateFrame("Frame", "SessionHPHEvents", UIParent)
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

EventFrame:SetScript("OnEvent", function(msg)
	msg      = arg1 or msg
	local e  = event

	if e == "PLAYER_LOGIN" then
		sessionStart = GetTime()
		sessionHonor = 0
		honorLog     = {}

		if SessionHPH_db and SessionHPH_db.x and SessionHPH_db.y then
			SessionHPHFrame:ClearAllPoints()
			SessionHPHFrame:SetPoint("CENTER", UIParent, "CENTER", SessionHPH_db.x, SessionHPH_db.y)
		end
		return
	end

	if (e == "CHAT_MSG_COMBAT_HONOR_GAIN" or e == "CHAT_MSG_SYSTEM") and msg and type(msg) == "string" then
		if e == "CHAT_MSG_SYSTEM" and not string.find(msg, "honor") then
			return
		end
		local honor = tonumber(matchOne(msg, "awarded%s*(%d+)%s*honor%s*points%.?"))
			or tonumber(matchOne(msg, "(%d+)%s*honor%s*points%.?"))
			or tonumber(matchOne(msg, "Estimated Honor Points: (%d+)"))
			or tonumber(matchOne(msg, "(%d+)%)"))
			or tonumber(matchOne(msg, "(%d+)%s*[hH]onor"))
			or tonumber(matchOne(msg, "(%d+)%s*[hH]onneur"))
			or (e == "CHAT_MSG_COMBAT_HONOR_GAIN" and tonumber(matchOne(msg, "(%d+)")))
		addHonor(honor)
	end
end)

-- Main display frame
local Frame = CreateFrame("Frame", "SessionHPHFrame", UIParent)
Frame:SetMovable(true)
Frame:EnableMouse(true)
Frame:RegisterForDrag("LeftButton")
Frame:SetWidth(165)
Frame:SetHeight(118)
Frame:SetAlpha(0.9)
Frame:SetPoint("CENTER", 0, 0)
Frame:SetUserPlaced(true)

Frame:SetBackdrop({
	bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true,
	tileSize = 16,
	edgeSize = 16,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
Frame:SetBackdropColor(0, 0, 0, 0.6)
Frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

Frame:SetScript("OnDragStart", function() Frame:StartMoving() end)
Frame:SetScript("OnDragStop", function()
	Frame:StopMovingOrSizing()
	local _, _, _, x, y = Frame:GetPoint(1)
	if not SessionHPH_db then SessionHPH_db = {} end
	SessionHPH_db.x = x
	SessionHPH_db.y = y
end)

-- 6 lines, 15px apart, centered in the frame
-- Positions from frame center: +37, +22, +7, -8, -23

-- Line 1: Week (light blue)
Frame.line1 = Frame:CreateFontString(nil, "ARTWORK")
Frame.line1:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
Frame.line1:SetPoint("CENTER", Frame, "CENTER", 0, 37)
Frame.line1:SetJustifyH("CENTER")
Frame.line1:SetTextColor(0.4, 0.8, 1, 1)

-- Line 2: Past hour (orange)
Frame.line2 = Frame:CreateFontString(nil, "ARTWORK")
Frame.line2:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
Frame.line2:SetPoint("CENTER", Frame, "CENTER", 0, 22)
Frame.line2:SetJustifyH("CENTER")
Frame.line2:SetTextColor(1, 0.6, 0.2, 1)

-- Line 3: Session honor (white)
Frame.line3 = Frame:CreateFontString(nil, "ARTWORK")
Frame.line3:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
Frame.line3:SetPoint("CENTER", Frame, "CENTER", 0, 7)
Frame.line3:SetJustifyH("CENTER")
Frame.line3:SetTextColor(1, 1, 1, 1)

-- Line 4: Honor/h (yellow, slightly larger)
Frame.line4 = Frame:CreateFontString(nil, "ARTWORK")
Frame.line4:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
Frame.line4:SetPoint("CENTER", Frame, "CENTER", 0, -8)
Frame.line4:SetJustifyH("CENTER")
Frame.line4:SetTextColor(1, 0.98, 0, 1)

-- Line 5: Session time (gray)
Frame.line5 = Frame:CreateFontString(nil, "ARTWORK")
Frame.line5:SetFont("Fonts\\ARIALN.ttf", 11, "OUTLINE")
Frame.line5:SetPoint("CENTER", Frame, "CENTER", 0, -23)
Frame.line5:SetJustifyH("CENTER")
Frame.line5:SetTextColor(0.7, 0.7, 0.7, 1)

-- Throttled OnUpdate (1s)
Frame:SetScript("OnUpdate", function(elapsed)
	if not elapsed then
		local t = GetTime()
		elapsed  = lastTick > 0 and (t - lastTick) or 0
		lastTick = t
	end
	lastUpdate = lastUpdate + elapsed
	if lastUpdate < 1 then return end
	lastUpdate = 0

	local now        = GetTime()
	local elapsedSec = now - sessionStart

	-- Honor/h
	local hph = elapsedSec > 0 and math.floor(3600 * sessionHonor / elapsedSec) or 0

	-- Session time string
	local totalM = math.floor(elapsedSec / 60)
	local hours  = math.floor(totalM / 60)
	local mins   = totalM - hours * 60
	local timeStr = hours .. "h " .. mins .. "m"

	-- Week from game API (hk, hp) — we use hp only
	local weeklyHonor = 0
	if GetPVPThisWeekStats then
		local _, hp = GetPVPThisWeekStats()
		weeklyHonor = tonumber(hp) or 0
	end

	-- Past hour: prune log and sum
	local cutoff     = now - 3600
	local pastHour   = 0
	local newLog     = {}
	for _, entry in ipairs(honorLog) do
		if entry.t >= cutoff then
			pastHour = pastHour + entry.amount
			table.insert(newLog, entry)
		end
	end
	honorLog = newLog

	Frame.line1:SetText("Week: "       .. formatHonor(weeklyHonor))
	Frame.line2:SetText("Last hour: "  .. formatHonor(pastHour))
	Frame.line3:SetText("Session: "    .. formatHonor(sessionHonor))
	Frame.line4:SetText("Honor/h: "    .. formatHonor(hph))
	Frame.line5:SetText(timeStr)
end)

-- /hph toggle | /hph reset
SLASH_SESSIONHPH1 = "/hph"
SlashCmdList["SESSIONHPH"] = function(msg)
	local arg = msg and string.gsub(msg, "^%s+", "") or ""
	if string.lower(arg) == "reset" then
		Frame:ClearAllPoints()
		Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		if not SessionHPH_db then SessionHPH_db = {} end
		SessionHPH_db.x = 0
		SessionHPH_db.y = 0
		Frame:Show()
	else
		if SessionHPHFrame:IsShown() then
			SessionHPHFrame:Hide()
		else
			SessionHPHFrame:Show()
		end
	end
end
