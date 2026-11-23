local WindUI = require("../src/Init")

local Window = WindUI:CreateWindow({ Title = "Smoke", NewElements = true, Size = UDim2.fromOffset(700, 500) })
local Tab = Window:Tab({ Title = "Test" })
local Hits = 0
local D = Tab:Dropdown({
	Title = "Pick",
	Values = { "Alpha", "Bravo", "Charlie" },
	Value = "Alpha",
	Callback = function()
		Hits += 1
	end,
})

D:Open()
assert(D.UIElements.MenuCanvas.Visible, "menu not visible")
assert(#D.Tabs == 3, "rows not built: " .. tostring(#D.Tabs))
for _, Callback in ipairs(D.Tabs[2].UIElements.TabItem.MouseButton1Up.__callbacks or {}) do
	Callback()
end
assert(D.Value == "Bravo", "value not updated: " .. tostring(D.Value))
assert(Hits == 1, "callback count: " .. tostring(Hits))
print("DROPDOWN_SMOKE_OK rows=" .. #D.Tabs)
