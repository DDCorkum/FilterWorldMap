--[[

## Title: FilterWorldMap
## Notes: Removes icons from the WorldMapFrame
## Author: Dahk Celes (DDCorkum)
## X-License: Public Domain.  Please clearly mark changes.  <http://unlicense.org>
## Version: 1.1


Changelog by

1.1 (8 May 2020) by Dahk Celes
- Filters can be turned on/off from drop-down options in the WorldMapFrame
- Renaming from 'HideWorldMapFrame' to 'FilterWorldMap'

1.0 (7 May 2020) by Dahk Celes
- Initial version requested by a user on WoWI

--]]

---- CONSTANTS ----

-- List of all templates that can be hidden, and a localized option name from GlobalStrings.lua
local ALL_OPTIONS =
{
	["AreaPOIPinTemplate"] = MINIMAP_TRACKING_POI,
	["BonusObjectivePinTemplate"] = TRACKER_HEADER_BONUS_OBJECTIVES,
}

-- List of templates to be hidden by default
local DEFAULT_OPTIONS =
{
	-- ["AreaPOIPinTemplate"] = true,		-- example only; for now, this table is empty because the default is to filter nothing.
}


---- ACTUAL CODE ----

-- Everything happens at PLAYER_LOGIN.
-- No reason this couldn't be sooner at ADDON_LOADED.  I'm just lazy.


local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:SetScript("OnEvent", function()

	-- Initialize the options if it doesn't exist
	local toHide = FilterWorldMapOptions or Mixin({}, DEFAULT_OPTIONS)
	FilterWorldMapOptions = toHide

	-- Self explanatory.  See Blizzard_MapCanvas.lua
	local function removeUnwantedPins()
		for template in pairs(toHide) do
			WorldMapFrame:RemoveAllPinsByTemplate(template)
		end	
	end

	-- Hook everything the WorldMapFrame does.  (This might be overkill.)
	hooksecurefunc(WorldMapFrame, "RefreshAllDataProviders", removeUnwantedPins)
	hooksecurefunc(WorldMapFrame, "OnMapChanged", removeUnwantedPins)
	WorldMapFrame:HookScript("OnShow", removeUnwantedPins)
	WorldMapFrame:HookScript("OnEvent", removeUnwantedPins)
	

	-- Append the options to the WorldMapTrackingOptionsButton drop down menu
	-- Caution: on the world map it appears as 'filters' so checked means toHide=nil, unchecked means toHide=true
	local button = WorldMapFrame.overlayFrames[2]
	if (button.InitializeDropDown) then
		hooksecurefunc(button, "InitializeDropDown", function()
			local info = UIDropDownMenu_CreateInfo()
			
			UIDropDownMenu_AddSeparator()
			
			info.isTitle = true
			info.notCheckable = true
			info.text = WORLD_MAP_FILTER_TITLE .. "       |cff666666(FilterWorldMap)"
			UIDropDownMenu_AddButton(info)
			
			info.isTitle = nil
			info.disabled = nil
			info.notCheckable = nil
			info.isNotRadio = true
			info.keepShownOnClick = true
			
			for template, name in pairs(ALL_OPTIONS) do
				info.text = name 
				info.value = template
				info.checked = not toHide[template]
				info.func = function(btn) 
					toHide[btn.value] = not btn.checked or nil
					WorldMapFrame:RefreshAllDataProviders()
					
					-- Restore this if recreating the interface options panel that is commented out below
					--for __, cb in ipairs(panel) do
					--	if (cb.template == btn.value) then
					--		cb:SetChecked(not btn.checked)
					--	end
					--end
					
				end
				UIDropDownMenu_AddButton(info)
			end
			
		end)
	end
	
	
	--[[
	
		-- Variant of original v1.0 code that would have put the options in an interface panel.
		-- This isn't necessary since the filters are available from a dropdown right in the world map
		
				-- Create an interface panel with the options
				local originalOptions = {}
	
				local function setOption(cb)
					originalOptions[cb.template] = originalOptions[cb.template] or not cb:GetChecked()
					toHide[cb.template] = cb:GetChecked() or nil
					if WorldMapFrame:IsShown() then
						WorldMapFrame:RefreshAllDataProviders()
					end
				end
	
				local panel = CreateFrame("Frame")
				panel.name = "HideWorldMapIcons"
				panel.okay = function()
					wipe(originalOptions)
				end
				panel.cancel = function()
					for template, val in pairs(originalOptions) do
						toHide[template] = val or nil
					end
					for __, cb in ipairs(panel) do
						cb:SetChecked(toHide[cb.template])
					end
				end
				panel.default = function()
					wipe(toHide)
					Mixin(toHide, DEFAULT_OPTIONS)
					for __, cb in ipairs(panel) do
						cb:SetChecked(toHide[cb.template])
					end
				end
	
				local i=1
				local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
				fs:SetText(CLICK_TO_REMOVE_ADDITIONAL_QUEST_LOCATIONS)
				fs:SetTextColor(0.9, 0.9, 0.9)
				fs:SetPoint("TOPLEFT", panel, 20, -20)
				for template, name in pairs(ALL_OPTIONS) do
					local cb = CreateFrame("CheckButton", "FilterWorldMapInterfaceOptionsCheckButton" .. i, panel, "OptionsCheckButtonTemplate")
					cb.template = template
					_G["FilterWorldMapInterfaceOptionsCheckButton" .. i .. "Text"]:SetText(name)
					cb:SetChecked(toHide[template])
					cb:SetScript("OnClick", setOption)
					cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -20 -(i*30))
					panel[i] = cb
					i = i+1
				end
	
				InterfaceOptions_AddCategory(panel)
		
				-- Add a slash command
				SlashCmdList.FILTERWORLDMAP = function() InterfaceOptionsFrame_OpenToCategory(panel) end
				SLASH_FILTERWORLDMAP1 = "/FilterWorldMap"		


	--]]

end)
