-- Mirrors the dropdown patterns from main_example.lua.
local WindUI = require("../src/Init")

local Window = WindUI:CreateWindow({
	Title = "Example dropdowns",
	Folder = "test",
	Icon = "solar:folder-2-bold-duotone",
	NewElements = true,
	HideSearchBar = false,
	Topbar = { Height = 44, ButtonsType = "Mac" },
})

local ElementsSection = Window:Section({ Title = "Elements" })
local DropdownTab = ElementsSection:Tab({
	Title = "Dropdown",
	Icon = "solar:hamburger-menu-bold",
	IconColor = Color3.fromHex("#ECA201"),
	IconShape = "Square",
	Border = true,
})

local clicked = 0
local Advanced = DropdownTab:Dropdown({
	Title = "Advanced Dropdown (example)",
	Values = {
		{ Title = "New file", Desc = "Create a new file", Icon = "file-plus", Callback = function() clicked += 1 end },
		{ Title = "Copy link", Desc = "Copy the file link", Icon = "copy", Callback = function() clicked += 1 end },
		{ Type = "Divider" },
		{ Title = "Delete file", Desc = "Permanently delete the file", Icon = "trash", Callback = function() clicked += 1 end },
	},
})

-- Menu-style row must open from Main.MouseButton1Up.
local AdvancedCallbacks = Advanced.DropdownFrame.UIElements.Main.MouseButton1Up.__callbacks or {}
assert(#AdvancedCallbacks > 0, "menu-style dropdown has no row release handler")
for _, Callback in ipairs(AdvancedCallbacks) do
	Callback()
end
assert(Advanced.UIElements.MenuCanvas.Visible, "menu-style dropdown did not open")

local Multi = DropdownTab:Dropdown({
	Title = "Multi Dropdown",
	Values = { "Привет", "Hello", "Сәлем", "Bonjour" },
	Value = nil,
	AllowNone = true,
	Multi = true,
	Callback = function() end,
})

local Single = DropdownTab:Dropdown({
	Title = "No Multi Dropdown",
	Values = { "Привет", "Hello", "Сәлем", "Bonjour" },
	Value = 1,
	Callback = function() end,
})

local LargeListA = {}
for Index = 1, 100 do
	LargeListA[Index] = Index == 1 and "All" or ("Item A" .. Index)
end
local LargeListB = {}
for Index = 1, 10 do
	LargeListB[Index] = "Data B" .. Index
end

local dropdownA
DropdownTab:Dropdown({
	Title = "Main Category",
	Values = { "All", "Other Option" },
	Value = "All",
	Callback = function(option)
		if dropdownA then
			if option == "All" then
				dropdownA:Refresh(LargeListA)
			else
				dropdownA:Refresh(LargeListB)
			end
			dropdownA:Select({ "All" })
		end
	end,
})

dropdownA = DropdownTab:Dropdown({
	Title = "Target",
	Values = LargeListA,
	Multi = true,
	Value = { "All" },
	Callback = function() end,
})

assert(#dropdownA.Tabs == 100, "large list did not build 100 rows: " .. #dropdownA.Tabs)
assert(#Multi.Tabs == 4, "multi list did not build")
assert(#Single.Tabs == 4, "single list did not build")

dropdownA:Open()
assert(dropdownA.UIElements.MenuCanvas.Visible, "large dropdown did not open")
dropdownA:Close()

dropdownA:Refresh(LargeListB)
assert(#dropdownA.Tabs == 10, "Refresh(B) did not rebuild: " .. #dropdownA.Tabs)
dropdownA:Select({ "Data B1" })
assert(table.concat(dropdownA.Value, ",") == "Data B1", "multi select failed")

local MultiCallbacks = Multi.UIElements.Dropdown.MouseButton1Up.__callbacks or {}
assert(#MultiCallbacks > 0, "multi trigger has no release handler")
for _, Callback in ipairs(MultiCallbacks) do
	Callback()
end
assert(Multi.UIElements.MenuCanvas.Visible, "multi trigger did not open")

Multi:Open()
for _, Callback in ipairs(Multi.Tabs[2].UIElements.TabItem.MouseButton1Up.__callbacks or {}) do
	Callback()
end
assert(#Multi.Value == 1 and Multi.Value[1] == "Hello", "multi row release failed")

print("EXAMPLE_DROPDOWNS_OK large=" .. #LargeListA .. " refreshed=" .. #dropdownA.Tabs)
