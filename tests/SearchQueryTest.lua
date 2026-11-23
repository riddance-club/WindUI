-- Headless regression test for the window search query walker.
-- Run with: luau tests/SearchQueryTest.lua
local Query = require("../src/components/search/Query")

local function Element(elemType, title, desc)
	return {
		__type = elemType,
		Title = title,
		Desc = desc,
	}
end

local Aim = Element("Toggle", "Aim Assist", "Smooth targeting")
local Esp = Element("Toggle", "Player ESP", "Highlight players")
local NestedToggle = Element("Toggle", "Auto Parry", "Block automatically")
local NestedKeybind = Element("Keybind", "Open Menu", "RightShift")

local DeepToggle = Element("Toggle", "Silent Aim", "Nested group toggle")
local DeepGroup = {
	__type = "Group",
	Elements = { DeepToggle },
}

local Section = {
	__type = "Section",
	Title = "Combat",
	Elements = { NestedToggle, NestedKeybind, DeepGroup },
}

-- This mirrors the fixed registration layout: nested elements belong to their
-- Section/Group and must not overwrite the tab's own entries at local indices.
local Tab = {
	__type = "Tab",
	Title = "Main",
	Elements = { Aim, Section, Esp },
}

-- Deliberately duplicate a nested element in the tab list to make sure the
-- walker deduplicates by element identity instead of rendering it twice.
Tab.Elements[4] = NestedToggle

local TabModule = {
	Tabs = { Tab },
}

local function Titles(results)
	local out = {}
	for _, tab in ipairs(results) do
		for _, elem in ipairs(tab.Elements) do
			out[#out + 1] = elem.Title
		end
	end
	return out
end

local function Contains(list, title)
	for _, value in ipairs(list) do
		if value == title then
			return true
		end
	end
	return false
end

local aimResults = Query.Find(TabModule, "aim")
local aimTitles = Titles(aimResults)
assert(Contains(aimTitles, "Aim Assist"), "top-level toggle disappeared")
assert(Contains(aimTitles, "Silent Aim"), "grouped toggle disappeared")
local silentResult
for _, tab in ipairs(aimResults) do
	for _, elem in ipairs(tab.Elements) do
		if elem.Title == "Silent Aim" then
			silentResult = elem
		end
	end
end
assert(silentResult and silentResult.Ancestors[1] == Section, "grouped toggle lost its section ancestor")
assert(#aimTitles == 2, "unexpected aim results: " .. table.concat(aimTitles, ", "))

local autoResults = Query.Find(TabModule, "auto")
local autoTitles = Titles(autoResults)
assert(Contains(autoTitles, "Auto Parry"), "section toggle disappeared")
assert(#autoTitles == 1, "unexpected auto results: " .. table.concat(autoTitles, ", "))
assert(#autoResults[1].Elements[1].Ancestors == 1, "section ancestor was not recorded")
assert(autoResults[1].Elements[1].Ancestors[1] == Section, "wrong section ancestor")

local toggleResults = Query.Find(TabModule, "toggle")
local toggleTitles = Titles(toggleResults)
for _, title in ipairs({ "Aim Assist", "Player ESP", "Auto Parry", "Silent Aim" }) do
	assert(Contains(toggleTitles, title), "type search missed " .. title)
end
assert(#toggleTitles == 4, "type search duplicated or missed elements: " .. table.concat(toggleTitles, ", "))

local keyResults = Query.Find(TabModule, "keybind")
local keyTitles = Titles(keyResults)
assert(Contains(keyTitles, "Open Menu"), "nested keybind disappeared")
assert(#keyTitles == 1, "unexpected keybind results: " .. table.concat(keyTitles, ", "))

local parryResults = Query.Find(TabModule, "parry")
assert(#parryResults == 1, "tab result missing")
assert(#parryResults[1].Elements == 1, "duplicate nested element rendered")
assert(parryResults[1].Elements[1].Original == NestedToggle, "wrong original element returned")
assert(#parryResults[1].Elements[1].Ancestors == 1, "duplicate path lost the section ancestor")

assert(#Query.Find(TabModule, "") == 0, "empty query should return no results")
assert(#Query.Find(TabModule, "zzzz") == 0, "unmatched query should return no results")

print("SEARCH_QUERY_TEST_OK")
