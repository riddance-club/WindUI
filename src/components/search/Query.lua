-- Pure query helpers for the window search bar.
--
-- Kept free of Roblox UI instances so the element walk and scoring can be
-- exercised by a headless Luau test. The previous implementation lived inline
-- in Init.lua and only walked Tab.Elements; nested elements (Sections, Groups,
-- HStacks, VStacks) were invisible whenever their container-local index had
-- overwritten a top-level tab entry.

local Query = {}

local CleanTextCache = {}

local function CleanText(str)
	if not str or type(str) ~= "string" then
		return ""
	end

	local Cached = CleanTextCache[str]
	if Cached then
		return Cached
	end

	local Cleaned = string.lower((string.gsub(str, "<[^<>]->", "")))
	CleanTextCache[str] = Cleaned
	return Cleaned
end

local function GetElementDetails(elem)
	local rawTitle = elem.Title or elem.Name or elem.Text or elem.Header or elem.Label
	if not rawTitle and elem.Config and type(elem.Config) == "table" then
		rawTitle = elem.Config.Title or elem.Config.Name or elem.Config.Text
	end

	local rawDesc = elem.Desc or elem.Description or elem.Tooltip or elem.SubTitle or elem.SubText
	if not rawDesc and elem.Config and type(elem.Config) == "table" then
		rawDesc = elem.Config.Desc or elem.Config.Description or elem.Config.Tooltip
	end

	local elemType = elem.__type or elem.Type or (elem.Config and elem.Config.Type) or "Button"

	return rawTitle and tostring(rawTitle) or "", rawDesc and tostring(rawDesc) or nil, tostring(elemType)
end

local function IsKeyQuery(queryLower)
	return string.find(queryLower, "key", 1, true) ~= nil
		or string.find(queryLower, "bind", 1, true) ~= nil
end

local function TypeMatchesQuery(elemType, queryLower, queryWords)
	local cleanType = CleanText(elemType)
	if cleanType == "" then
		return false
	end

	if cleanType == queryLower or string.find(cleanType, queryLower, 1, true) then
		return true
	end

	for _, word in ipairs(queryWords) do
		if not string.find(cleanType, word, 1, true) then
			return false
		end
	end

	return #queryWords > 0
end

function Query.CalculateElementScore(title, desc, elemType, queryLower, queryWords, isKeySearch)
	if queryLower == "" then
		return 0
	end

	local cleanTitle = CleanText(title)
	local cleanDesc = CleanText(desc)
	local score = 0

	if cleanTitle == queryLower then
		score = score + 120
	elseif string.sub(cleanTitle, 1, #queryLower) == queryLower then
		score = score + 70
	elseif string.find(cleanTitle, queryLower, 1, true) then
		score = score + 50
	elseif cleanDesc ~= "" and string.find(cleanDesc, queryLower, 1, true) then
		score = score + 20
	else
		local allWordsMatchTitle = true
		local allWordsMatchCombined = true

		for _, word in ipairs(queryWords) do
			local inTitle = string.find(cleanTitle, word, 1, true) ~= nil
			local inDesc = cleanDesc ~= "" and string.find(cleanDesc, word, 1, true) ~= nil

			if not inTitle then
				allWordsMatchTitle = false
			end
			if not inTitle and not inDesc then
				allWordsMatchCombined = false
			end
		end

		if allWordsMatchTitle then
			score = score + 45
		elseif allWordsMatchCombined then
			score = score + 25
		end
	end

	-- Let searches like "toggle" or "keybind" find elements by their type even
	-- when the user did not put the type in the element title.
	if score == 0 and TypeMatchesQuery(elemType, queryLower, queryWords) then
		score = 15
	end

	if score == 0 then
		return 0
	end

	if elemType == "Toggle" or elemType == "Button" then
		score = score + (isKeySearch and 0 or 30)
	elseif elemType == "Slider" or elemType == "Dropdown" or elemType == "Colorpicker" or elemType == "Input" then
		score = score + (isKeySearch and 0 or 25)
	elseif elemType == "Keybind" then
		score = score + (isKeySearch and 35 or -15)
	end

	-- A matching element must never disappear because of a type penalty.
	return math.max(score, 1)
end

local ContainerOnlyTypes = {
	Group = true,
	HStack = true,
	VStack = true,
}

local CollectElements

CollectElements = function(container, list, state, ancestors)
	if type(container) ~= "table" then
		return
	end
	if state.visited[container] then
		return
	end
	state.visited[container] = true

	local elementsTable = container.Elements or container
	if type(elementsTable) ~= "table" then
		return
	end

	ancestors = ancestors or {}

	for elemIndex, elem in next, elementsTable do
		if type(elem) == "table" then
			local rawTitle, rawDesc, elemType = GetElementDetails(elem)

			-- A collapsed Section still owns its rows, so remember the path to
			-- the element. The search bar can open those ancestors and then
			-- scroll to the row instead of landing on a clipped/invisible frame.
			local childAncestors = ancestors
			if elemType == "Section" then
				childAncestors = {}
				for index, ancestor in ipairs(ancestors) do
					childAncestors[index] = ancestor
				end
				childAncestors[#childAncestors + 1] = elem
			end

			-- Walk nested containers first. A Section/Group/HStack/VStack owns its
			-- children, and the tab never stores those children itself.
			if type(elem.Elements) == "table" then
				CollectElements(elem.Elements, list, state, childAncestors)
			end
			if type(elem.Children) == "table" then
				CollectElements(elem.Children, list, state, childAncestors)
			end
			if type(elem.Items) == "table" then
				CollectElements(elem.Items, list, state, childAncestors)
			end

			local isSearchable = elemType ~= "Section"
				and elemType ~= "Divider"
				and elemType ~= "Space"
				and not ContainerOnlyTypes[elemType]
				and (rawTitle ~= "" or rawDesc ~= nil)

			if isSearchable and not state.seen[elem] then
				state.seen[elem] = true
				table.insert(list, {
					Title = rawTitle,
					Desc = rawDesc,
					__type = elemType,
					Original = elem,
					Index = elemIndex,
					Ancestors = ancestors,
				})
			end
		end
	end

	if container.Sections and type(container.Sections) == "table" then
		for _, section in next, container.Sections do
			local sectionAncestors = {}
			for index, ancestor in ipairs(ancestors) do
				sectionAncestors[index] = ancestor
			end
			sectionAncestors[#sectionAncestors + 1] = section
			CollectElements(section, list, state, sectionAncestors)
		end
	end
end

function Query.CollectAllElements(Tab)
	local list = {}
	CollectElements(Tab, list, {
		visited = {},
		seen = {},
	}, {})
	return list
end

function Query.Find(TabModule, query)
	if not query or query == "" then
		return {}
	end

	local queryLower = CleanText(query)
	if queryLower == "" then
		return {}
	end

	local queryWords = {}
	for word in string.gmatch(queryLower, "%S+") do
		table.insert(queryWords, word)
	end

	local isKeySearch = IsKeyQuery(queryLower)
	local results = {}

	for tabIndex, tab in next, (TabModule and TabModule.Tabs) or {} do
		local tabTitle = tab.Title or (tab.Config and tab.Config.Title) or ""
		local cleanTabTitle = CleanText(tabTitle)
		local tabMatches = cleanTabTitle ~= "" and string.find(cleanTabTitle, queryLower, 1, true) ~= nil

		local allElements = Query.CollectAllElements(tab)
		local elementResults = {}

		for _, elem in ipairs(allElements) do
			local score =
				Query.CalculateElementScore(elem.Title, elem.Desc, elem.__type, queryLower, queryWords, isKeySearch)
			if score > 0 then
				table.insert(elementResults, {
					Title = elem.Title,
					Desc = elem.Desc,
					Original = elem.Original,
					__type = elem.__type,
					Index = elem.Index,
					Ancestors = elem.Ancestors,
					Score = score,
				})
			end
		end

		table.sort(elementResults, function(a, b)
			if a.Score == b.Score then
				return a.Title < b.Title
			end
			return a.Score > b.Score
		end)

		if tabMatches or #elementResults > 0 then
			table.insert(results, {
				Tab = tab,
				TabIndex = tabIndex,
				Title = tabTitle,
				Icon = tab.Icon,
				Elements = elementResults,
				Score = (#elementResults > 0 and elementResults[1].Score or 0) + (tabMatches and 50 or 0),
			})
		end
	end

	table.sort(results, function(a, b)
		if a.Score == b.Score then
			return a.Title < b.Title
		end
		return a.Score > b.Score
	end)

	return results
end

return Query
