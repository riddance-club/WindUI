local Registry = {}

function Registry.Load(tbl, Container, Elements, Window, WindUI, OnElementCreateFunction, ElementsModule, UIScale, Tab)
	local ElementFrameMap = setmetatable({}, { __mode = "k" })

	local function UpdateShapeForIndex(container, index)
		local element = container.Elements[index]
		if not element then
			return
		end

		local frame = ElementFrameMap[element]
		if not frame then
			for key, value in next, element do
				if typeof(value) == "table" and key:match("Frame$") then
					frame = value
					break
				end
			end
			if not frame and element.UpdateShape then
				frame = element
			end
			ElementFrameMap[element] = frame
		end

		if frame then
			frame.Index = index
			if frame.UpdateShape then
				frame.UpdateShape(container)
			end
		end
	end

	for name, module in next, Elements do
		tbl[name] = function(self, config)
			config = config or {}
			config.Tab = Tab or tbl
			config.ParentType = tbl.__type
			config.ParentTable = tbl
			config.Index = #tbl.Elements + 1
			config.GlobalIndex = #Window.AllElements + 1
			config.Parent = Container
			config.Window = Window
			config.WindUI = WindUI
			config.UIScale = UIScale
			config.ElementsModule = ElementsModule

			local _elementInstance, content = module:New(config)

			if config.Flag and typeof(config.Flag) == "string" then
				if Window.CurrentConfig then
					Window.CurrentConfig:Register(config.Flag, content)

					if Window.PendingConfigData and Window.PendingConfigData[config.Flag] then
						local data = Window.PendingConfigData[config.Flag]

						local ConfigManager = Window.ConfigManager
						if ConfigManager.Parser[data.__type] then
							task.defer(function()
								local success, err = pcall(function()
									ConfigManager.Parser[data.__type].Load(content, data)
								end)

								if success then
									Window.PendingConfigData[config.Flag] = nil
								else
									warn(
										"[ WindUI ] Failed to apply pending config for '"
											.. config.Flag
											.. "': "
											.. tostring(err)
									)
								end
							end)
						end
					end
				else
					Window.PendingFlags = Window.PendingFlags or {}
					Window.PendingFlags[config.Flag] = content
				end
			end

			local frame
			for key, value in next, content do
				if typeof(value) == "table" and key ~= "ElementFrame" and key:match("Frame$") then
					frame = value
					break
				end
			end

			if frame then
				ElementFrameMap[content] = frame
				content.ElementFrame = frame.UIElements.Main
				function content:SetTitle(title)
					return frame.SetTitle and frame:SetTitle(title)
				end
				function content:SetDesc(desc)
					return frame.SetDesc and frame:SetDesc(desc)
				end
				function content:SetImage(image, size)
					return frame.SetImage and frame:SetImage(image, size)
				end
				function content:SetThumbnail(image, size)
					return frame.SetThumbnail and frame:SetThumbnail(image, size)
				end
				function content:Highlight()
					frame:Highlight()
				end
				function content:Destroy()
					frame:Destroy()

					-- Window.AllElements is a flat, globally-indexed list. Nested
					-- elements (inside Sections, Groups, ...) have their own
					-- local index, so search for the object instead of trusting
					-- the stored index after earlier removals.
					local GlobalIndex = table.find(Window.AllElements, content)
					if GlobalIndex then
						table.remove(Window.AllElements, GlobalIndex)
					end

					local LocalIndex = table.find(tbl.Elements, content)
					if LocalIndex then
						table.remove(tbl.Elements, LocalIndex)
					end

					-- Only the tab owns the top-level elements. Nested containers
					-- keep their own Elements list and must not remove a sibling
					-- from the tab by reusing their local index.
					if tbl == Tab then
						local TabIndex = table.find(Tab.Elements, content)
						if TabIndex then
							table.remove(Tab.Elements, TabIndex)
						end
					end

					tbl:UpdateAllElementShapes(tbl)
				end
			end

			Window.AllElements[config.GlobalIndex] = content
			tbl.Elements[config.Index] = content
			-- Nested elements belong to their Section/Group/HStack table. Writing
			-- them into Tab.Elements with a container-local index overwrote real
			-- top-level elements (and hid whole sections from search).
			if Tab and tbl == Tab then
				Tab.Elements[config.Index] = content
			end

			if Window.NewElements then
				-- Appending an element can only change the shape of the previous
				-- last element and the new one, so don't re-scan every element.
				UpdateShapeForIndex(tbl, config.Index - 1)
				UpdateShapeForIndex(tbl, config.Index)
			end

			if OnElementCreateFunction then
				OnElementCreateFunction(content, tbl.Elements)
			end
			return content
		end
	end
	function tbl:UpdateAllElementShapes(bbb)
		local elements = bbb.Elements
		for i = 1, #elements do
			UpdateShapeForIndex(bbb, i)
		end
	end
end

return Registry
