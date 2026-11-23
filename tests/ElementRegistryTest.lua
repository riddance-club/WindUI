-- Regression test for element registration ownership.
--
-- The bug: nested elements (Section/Group/HStack) were written into
-- Tab.Elements using the container-local index. A Section's first toggle
-- overwrote the tab's first toggle, and a Section element could overwrite
-- itself, which made most elements unreachable from the search bar.
local Registry = require("../src/elements/Registry")
local Load = Registry.Load

typeof = type

local FakeFrame = {}
function FakeFrame:New()
	return {
		UIElements = { Main = {} },
		Destroy = function() end,
	}
end

local FakeModule = {}
function FakeModule:New(config)
	return "Fake", {
		__type = "Fake",
		Title = config.Title,
		FakeFrame = FakeFrame:New(),
	}
end

local Window = { AllElements = {}, NewElements = false }
local Tab = { __type = "Tab", Elements = {} }

Load(Tab, {}, { Fake = FakeModule }, Window, {}, nil, {}, 1, Tab)
local TopOne = Tab:Fake({ Title = "Top One" })
local TopTwo = Tab:Fake({ Title = "Top Two" })

local Section = { __type = "Section", Elements = {} }
Load(Section, {}, { Fake = FakeModule }, Window, {}, nil, {}, 1, Tab)
local NestedOne = Section:Fake({ Title = "Nested One" })

local Group = { __type = "Group", Elements = {} }
Load(Group, {}, { Fake = FakeModule }, Window, {}, nil, {}, 1, Tab)
local NestedTwo = Group:Fake({ Title = "Nested Two" })

-- Direct tab children stay exactly where they were created.
assert(#Tab.Elements == 2, "Tab.Elements should only hold top-level elements: " .. #Tab.Elements)
assert(Tab.Elements[1] == TopOne, "nested element overwrote the first tab element")
assert(Tab.Elements[2] == TopTwo, "nested element overwrote the second tab element")
assert(Section.Elements[1] == NestedOne, "Section did not keep its own child")
assert(Group.Elements[1] == NestedTwo, "Group did not keep its own child")

-- Every element still has a unique slot in the flat window list.
assert(#Window.AllElements == 4, "Window.AllElements lost elements: " .. #Window.AllElements)
assert(Window.AllElements[1] == TopOne)
assert(Window.AllElements[2] == TopTwo)
assert(Window.AllElements[3] == NestedOne)
assert(Window.AllElements[4] == NestedTwo)

-- Destroying a nested element must not remove an unrelated tab element that
-- happens to have the same local index.
NestedOne:Destroy()
assert(#Tab.Elements == 2, "destroying a nested element removed a tab element")
assert(Tab.Elements[1] == TopOne and Tab.Elements[2] == TopTwo, "tab elements shifted incorrectly")
assert(#Window.AllElements == 3, "Window.AllElements did not drop the destroyed element")
assert(Window.AllElements[1] == TopOne and Window.AllElements[3] == NestedTwo, "flat list shifted incorrectly")

TopOne:Destroy()
assert(#Tab.Elements == 1 and Tab.Elements[1] == TopTwo, "destroying a tab element left a hole")
assert(#Window.AllElements == 2, "Window.AllElements did not drop the tab element")

print("ELEMENT_REGISTRY_TEST_OK")
