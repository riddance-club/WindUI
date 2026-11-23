-- Dropdown regression test aligned with stock WindUI behaviour.
local WindUI = require("../src/Init")

local Window = WindUI:CreateWindow({
	Title = "Dropdown Test",
	Size = UDim2.fromOffset(700, 480),
	NewElements = true,
})

local Tab = Window:Tab({ Title = "Dropdowns" })
local LastCallback = nil

local Dropdown = Tab:Dropdown({
	Title = "Pick a value",
	Desc = "Dropdown regression test",
	Values = { "Alpha", "Bravo", "Charlie" },
	Value = "Alpha",
	Callback = function(value)
		LastCallback = value
	end,
})

assert(Dropdown, "dropdown element was not returned")
assert(Dropdown.UIElements.Dropdown, "dropdown trigger is missing")
assert(Dropdown.__type == "Dropdown", "wrong element type")
assert(#Dropdown.Tabs == 3, "rows were not built at creation")

Dropdown:Open()
assert(Dropdown.UIElements.MenuCanvas.Visible, "menu did not open")
assert(Dropdown.UIElements.Menu.Visible, "menu frame did not open")

WindUI.DropdownGui.AbsoluteSize = Vector2.new(1920, 1080)
local LayoutSignal = Dropdown.UIElements.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize")
Dropdown.UIElements.UIListLayout.AbsoluteContentSize = Vector2.new(0, 150)
for _, Callback in ipairs(LayoutSignal.__callbacks or {}) do
	Callback()
end
assert(
	Dropdown.UIElements.MenuCanvas.Size.Y.Offset > 100,
	"menu height did not follow layout: " .. tostring(Dropdown.UIElements.MenuCanvas.Size.Y.Offset)
)

for _, Callback in ipairs(Dropdown.Tabs[2].UIElements.TabItem.MouseButton1Up.__callbacks or {}) do
	Callback()
end
assert(Dropdown.Value == "Bravo", "value was not updated: " .. tostring(Dropdown.Value))
assert(LastCallback == "Bravo", "callback was not invoked with the selected value")
assert(Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Text == "Bravo", "trigger label was not updated")

Dropdown:Close()
assert(not Dropdown.Opened, "dropdown did not close")

-- Trigger release always opens (stock behaviour).
local TriggerCallbacks = Dropdown.UIElements.Dropdown.MouseButton1Up.__callbacks or {}
assert(#TriggerCallbacks > 0, "trigger has no release handler")
for _, Callback in ipairs(TriggerCallbacks) do
	Callback()
end
assert(Dropdown.UIElements.MenuCanvas.Visible, "trigger release did not open the menu")

-- Multi select.
local Multi = Tab:Dropdown({
	Title = "Multi",
	Values = { "One", "Two", "Three" },
	Multi = true,
	SearchBarEnabled = true,
	Callback = function() end,
})

assert(#Multi.Tabs == 3, "multi rows were not built")
Multi:Open()
for _, Index in ipairs({ 1, 2 }) do
	for _, Callback in ipairs(Multi.Tabs[Index].UIElements.TabItem.MouseButton1Up.__callbacks or {}) do
		Callback()
	end
end
assert(typeof(Multi.Value) == "table" and #Multi.Value == 2, "multi value did not collect selections")
assert(Multi.UIElements.Dropdown.Frame.Frame.TextLabel.Text == "One, Two", "multi label is wrong")

-- Refresh with a new list (config-style).
Multi:Refresh({ "Only" })
assert(#Multi.Tabs == 1, "Refresh did not rebuild rows: " .. tostring(#Multi.Tabs))

print("DROPDOWN_TEST_OK value=" .. tostring(Dropdown.Value) .. " multi=" .. tostring(#Multi.Value))
