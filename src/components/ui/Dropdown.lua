local DropdownMenu = {}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))
local Mouse = cloneref(game:GetService("Players").LocalPlayer:GetMouse())
local Camera = cloneref(game:GetService("Workspace")).CurrentCamera

local CurrentCamera = workspace.CurrentCamera

local CreateInput = require("./Input").New

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local TabBackgroundTransparency = 0.95

function DropdownMenu.New(Config, Dropdown, Element, Type)
	local DropdownModule = {}

	if not Dropdown.Callback then
		Type = "Menu"
	end

	Dropdown.UIElements.UIListLayout = New("UIListLayout", {
		Padding = UDim.new(0, Element.MenuPadding / 1.5),
		FillDirection = "Vertical",
		HorizontalAlignment = "Center",
	})

	-- Values may be a table or a function provider (e.g. ConfigStore.List).
	local function ResolveValues(Values)
		if type(Values) == "function" then
			local Success, Result = pcall(Values)
			if Success and type(Result) == "table" then
				return Result
			end
			warn("[ WindUI.Dropdown ] Values provider failed: " .. tostring(Result))
			return {}
		end
		return Values
	end

	-- Values can be strings, instances, or tables using common naming fields.
	local function GetValueLabel(Value)
		if typeof(Value) == "table" then
			return Value.Title or Value.Name or Value.Text or Value.Label or Value[1]
		end
		return Value
	end

	Dropdown.UIElements.Menu = Creator.NewRoundFrame(Element.MenuCorner, "Squircle", {
		ThemeTag = {
			ImageColor3 = "DropdownBackground",
		},
		ImageTransparency = 1, -- 0.05
		Size = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
	}, {
		-- Flat outline so the menu reads as a surface even when its background
		-- closely matches the window (1.6.57-style dark palette).
		Creator.NewRoundFrame(Element.MenuCorner, "SquircleOutline", {
			Size = UDim2.new(1, 0, 1, 0),
			ThemeTag = {
				ImageColor3 = "Outline",
			},
			ImageTransparency = 0.88,
			Name = "Border",
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, Element.MenuPadding),
			PaddingLeft = UDim.new(0, Element.MenuPadding),
			PaddingRight = UDim.new(0, Element.MenuPadding),
			PaddingBottom = UDim.new(0, Element.MenuPadding),
		}),
		New("UIListLayout", {
			FillDirection = "Vertical",
			Padding = UDim.new(0, Element.MenuPadding),
		}),
		New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, Dropdown.SearchBarEnabled and -Element.MenuPadding - Element.SearchBarHeight),
			--Name = "CanvasGroup",
			ClipsDescendants = true,
			LayoutOrder = 999,
			Name = "Frame",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Element.MenuCorner - Element.MenuPadding),
			}),
			New("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 0,
				ScrollingDirection = "Y",
				AutomaticCanvasSize = "Y",
				CanvasSize = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarImageTransparency = 1,
			}, {
				Dropdown.UIElements.UIListLayout,
			}),
		}),
	})

	Dropdown.UIElements.MenuCanvas = New("Frame", {
		Size = UDim2.new(0, Dropdown.MenuWidth, 0, 300),
		BackgroundTransparency = 1,
		Position = UDim2.new(-10, 0, -10, 0),
		Visible = false,
		Active = false,
		--GroupTransparency = 1, -- 0
		Parent = Config.WindUI.DropdownGui,
		AnchorPoint = Vector2.new(1, 0),
	}, {
		Dropdown.UIElements.Menu,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
			MaxSize = Vector2.new(300, 400),
		}),
	})

	local function RecalculateCanvasSize()
		Dropdown.UIElements.Menu.Frame.ScrollingFrame.CanvasSize =
			UDim2.fromOffset(0, Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y)
	end

	local function RecalculateListSize()
		local MaxHeight = Config.WindUI.DropdownGui.AbsoluteSize.Y
		if MaxHeight <= 0 then
			MaxHeight = 400
		end

		local ContentY = Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y / Config.UIScale
		if ContentY <= 0 then
			-- Layout has not run yet; use a row-count estimate (or a minimum
			-- for the empty-state row) until the layout signal gives us the
			-- real height.
			ContentY = math.max(#Dropdown.Tabs * 44, 40)
		end
		local SearchBarOffset = Dropdown.SearchBarEnabled and (Element.SearchBarHeight + (Element.MenuPadding * 3))
			or (Element.MenuPadding * 2)
		local TotalY = ContentY + SearchBarOffset

		local CanvasWidth = Dropdown.UIElements.MenuCanvas.AbsoluteSize.X
		if CanvasWidth <= 0 then
			CanvasWidth = Dropdown.UIElements.MenuCanvas.Size.X.Offset
		end

		if TotalY > MaxHeight then
			Dropdown.UIElements.MenuCanvas.Size = UDim2.fromOffset(CanvasWidth, MaxHeight)
		else
			Dropdown.UIElements.MenuCanvas.Size = UDim2.fromOffset(CanvasWidth, TotalY)
		end
	end

	local recalcPending = false
	local function ScheduleRecalc()
		if recalcPending then
			return
		end
		recalcPending = true
		task.defer(function()
			recalcPending = false
			RecalculateListSize()
			RecalculateCanvasSize()

			-- The menu height changed; re-run the flip/offset logic.
			if Dropdown.UIElements.MenuCanvas.Visible then
				UpdatePosition()
			end
		end)
	end

	function UpdatePosition()
		local button = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
		local menu = Dropdown.UIElements.MenuCanvas

		local ActiveCamera = workspace.CurrentCamera or Camera
		local availableSpaceBelow = ActiveCamera.ViewportSize.Y
			- (button.AbsolutePosition.Y + button.AbsoluteSize.Y)
			- Element.MenuPadding
			- 54
		local requiredSpace = menu.AbsoluteSize.Y + Element.MenuPadding

		local offset = -54 -- topbar offset
		if availableSpaceBelow < requiredSpace then
			offset = requiredSpace - availableSpaceBelow - 54
		end

		menu.Position = UDim2.new(
			0,
			button.AbsolutePosition.X + button.AbsoluteSize.X,
			0,
			button.AbsolutePosition.Y + button.AbsoluteSize.Y - offset + (Element.MenuPadding * 2)
		)
	end

	local SearchLabel

	function DropdownModule:Display()
		local Str = ""

		if Dropdown.Multi then
			local Values = ResolveValues(Dropdown.Values)
			local selected = {}
			if typeof(Dropdown.Value) == "table" then
				for _, item in ipairs(Dropdown.Value) do
					selected[GetValueLabel(item)] = true
				end
			end

			local Parts = {}
			for _, value in ipairs(Values) do
				local title = GetValueLabel(value)
				if selected[title] then
					Parts[#Parts + 1] = tostring(title)
				end
			end

			Str = table.concat(Parts, ", ")
		else
			Str = typeof(Dropdown.Value) == "table" and (GetValueLabel(Dropdown.Value) or Dropdown.Value[1])
				or Dropdown.Value
				or ""
		end

		if Dropdown.UIElements.Dropdown then
			Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Text = tostring(Str == "" and "--" or Str)
		end
	end

	local function Callback(customCallback)
		DropdownModule:Display()
		if Dropdown.Locked then
			return
		end

		if Dropdown.Callback then
			task.spawn(function()
				if Dropdown.Locked then
					return
				end
				Creator.SafeCallback(Dropdown.Callback, Dropdown.Value)
			end)
		else
			task.spawn(function()
				if Dropdown.Locked then
					return
				end
				Creator.SafeCallback(customCallback)
			end)
		end
	end

	function DropdownModule:LockValues(lockedItems)
		if not lockedItems then
			return
		end

		for _, tab in next, Dropdown.Tabs do
			if tab and tab.UIElements and tab.UIElements.TabItem then
				local itemName = tab.Name
				local isLocked = false

				for _, lockedItem in next, lockedItems do
					if itemName == lockedItem then
						isLocked = true
						break
					end
				end

				if isLocked then
					Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
					Tween(tab.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
					Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0.6 }):Play()
					if tab.UIElements.TabIcon then
						Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.6 }):Play()
					end

					tab.UIElements.TabItem.Active = false
					tab.Locked = true
				else
					if tab.Selected then
						Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = TabBackgroundTransparency }):Play()
						Tween(tab.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 0.75 }):Play()
						Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
						if tab.UIElements.TabIcon then
							Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
						end
					else
						Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
						Tween(tab.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
						Tween(
							tab.UIElements.TabItem.Frame.Title.TextLabel,
							0.1,
							{ TextTransparency = Type == "Dropdown" and 0.4 or 0.05 }
						):Play()
						if tab.UIElements.TabIcon then
							Tween(
								tab.UIElements.TabIcon.ImageLabel,
								0.1,
								{ ImageTransparency = Type == "Dropdown" and 0.2 or 0 }
							):Play()
						end
					end

					tab.UIElements.TabItem.Active = true
					tab.Locked = false
				end
			end
		end
	end

	function DropdownModule:Refresh(Values, silent)
		if Config.Window.Destroyed then
			return
		end

		-- Support Refresh() (use current values), function providers, and guard
		-- against a non-table slipping in through a mis-called method.
		local Source = Values or Dropdown.Values
		Values = ResolveValues(Source)
		if type(Values) ~= "table" then
			warn("[ WindUI.Dropdown ] Refresh expects a table of values")
			return
		end

		if type(Source) ~= "function" then
			Dropdown.Values = Values
		end
		builtValues = Values
		builtCount = #Values

		for _, Elementt in next, Dropdown.UIElements.Menu.Frame.ScrollingFrame:GetChildren() do
			if not Elementt:IsA("UIListLayout") then
				Elementt:Destroy()
			end
		end

		Dropdown.Tabs = {}
		local RowCount = 0

		if Dropdown.SearchBarEnabled then
			if not SearchLabel then
				SearchLabel = CreateInput("Search...", "search", Dropdown.UIElements.Menu, nil, function(val)
					local Query = string.lower(val)
					for _, tab in next, Dropdown.Tabs do
						tab.UIElements.TabItem.Visible =
							string.find(string.lower(tostring(tab.Name)), Query, 1, true) ~= nil
					end
					-- Defer so the layout has applied the new row visibility.
					ScheduleRecalc()
				end, true)
				SearchLabel.Size = UDim2.new(1, 0, 0, Element.SearchBarHeight)
				SearchLabel.Position = UDim2.new(0, 0, 0, 0)
				SearchLabel.Name = "SearchBar"
			end
		end

		for Index, Tab in next, Values do
			local TabIsTable = typeof(Tab) == "table"
			if not TabIsTable or Tab.Type ~= "Divider" then
				local TabMain = {
					Name = TabIsTable and (Tab.Title or Tab.Name or Tab.Text or Tab.Label or Tab[1]) or Tab,
					Desc = TabIsTable and (Tab.Desc or Tab.Description or Tab.SubTitle) or nil,
					Icon = TabIsTable and Tab.Icon or nil,
					IconSize = TabIsTable and Tab.IconSize or nil,
					Original = Tab,
					Selected = false,
					Locked = TabIsTable and Tab.Locked or false,
					UIElements = {},
				}
				local TabIcon
				if TabMain.Icon then
					TabIcon = Creator.Image(TabMain.Icon, TabMain.Icon, 0, Config.Window.Folder, "Dropdown", true)
					TabIcon.Size =
						UDim2.new(0, TabMain.IconSize or Element.TabIcon, 0, TabMain.IconSize or Element.TabIcon)
					TabIcon.ImageLabel.ImageTransparency = Type == "Dropdown" and 0.2 or 0
					TabMain.UIElements.TabIcon = TabIcon
				end
				TabMain.UIElements.TabItem = Creator.NewRoundFrame(
					Element.MenuCorner - Element.MenuPadding,
					"Squircle",
					{
						Size = UDim2.new(1, 0, 0, 36),
						AutomaticSize = TabMain.Desc and "Y",
						ImageTransparency = 1, -- 0
						Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame,
						--ImageColor3 = Color3.new(1, 1, 1),
						ThemeTag = {
							ImageColor3 = "DropdownTabBackground",
						},
						Active = not TabMain.Locked,
					},
					{
						Creator.NewRoundFrame(Element.MenuCorner - Element.MenuPadding, "SquircleOutline", {
							Size = UDim2.new(1, 0, 1, 0),
							ThemeTag = {
								ImageColor3 = "DropdownTabBorder",
							},
							ImageTransparency = 1, -- .75
							Name = "Highlight",
						}, {
							-- New("UIGradient", {
							--     Rotation = 80,
							--     Color = ColorSequence.new({
							--         ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
							--         ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
							--         ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
							--     }),
							--     Transparency = NumberSequence.new({
							--         NumberSequenceKeypoint.new(0.0, 0.1),
							--         NumberSequenceKeypoint.new(0.5, 1),
							--         NumberSequenceKeypoint.new(1.0, 0.1),
							--     })
							-- }),
						}),
						New("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
						}, {
							New("UIListLayout", {
								Padding = UDim.new(0, Element.TabPadding),
								FillDirection = "Horizontal",
								VerticalAlignment = "Center",
							}),
							New("UIPadding", {
								PaddingTop = UDim.new(0, Element.TabPadding),
								PaddingLeft = UDim.new(0, Element.TabPadding),
								PaddingRight = UDim.new(0, Element.TabPadding),
								PaddingBottom = UDim.new(0, Element.TabPadding),
							}),
							New("UICorner", {
								CornerRadius = UDim.new(0, Element.MenuCorner - Element.MenuPadding),
							}),
							TabIcon,
							New("Frame", {
								Size = UDim2.new(1, TabIcon and -Element.TabPadding - Element.TabIcon or 0, 0, 0),
								BackgroundTransparency = 1,
								AutomaticSize = "Y",
								Name = "Title",
							}, {
								New("TextLabel", {
									Text = tostring(TabMain.Name or ""),
									TextXAlignment = "Left",
									FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
									ThemeTag = {
										TextColor3 = "Text",
										BackgroundColor3 = "Text",
									},
									TextSize = 15,
									BackgroundTransparency = 1,
									TextTransparency = Type == "Dropdown" and 0.4 or 0.05,
									LayoutOrder = 999,
									AutomaticSize = "Y",
									Size = UDim2.new(1, 0, 0, 0),
								}),
								New("TextLabel", {
									Text = TabMain.Desc or "",
									TextXAlignment = "Left",
									FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
									ThemeTag = {
										TextColor3 = "Text",
										BackgroundColor3 = "Text",
									},
									TextSize = 15,
									BackgroundTransparency = 1,
									TextTransparency = Type == "Dropdown" and 0.6 or 0.35,
									LayoutOrder = 999,
									AutomaticSize = "Y",
									TextWrapped = true,
									Size = UDim2.new(1, 0, 0, 0),
									Visible = TabMain.Desc and true or false,
									Name = "Desc",
								}),
								New("UIListLayout", {
									Padding = UDim.new(0, Element.TabPadding / 3),
									FillDirection = "Vertical",
								}),
							}),
						}),
					},
					true
				)

				if TabMain.Locked then
					TabMain.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency = 0.6
					if TabMain.UIElements.TabIcon then
						TabMain.UIElements.TabIcon.ImageLabel.ImageTransparency = 0.6
					end
				end

				if Dropdown.Multi and typeof(Dropdown.Value) == "string" then
					for _, i in next, Dropdown.Values do
						if typeof(i) == "table" then
							if GetValueLabel(i) == Dropdown.Value then
								Dropdown.Value = { i }
							end
						else
							if i == Dropdown.Value then
								Dropdown.Value = { Dropdown.Value }
							end
						end
					end
				end

				if Dropdown.Multi then
					local found = false
					if typeof(Dropdown.Value) == "table" then
						for _, item in ipairs(Dropdown.Value) do
							local itemName = GetValueLabel(item)
							if itemName == TabMain.Name then
								found = true
								break
							end
						end
					end
					TabMain.Selected = found
				else
					local currentValue = typeof(Dropdown.Value) == "table" and GetValueLabel(Dropdown.Value)
						or Dropdown.Value
					TabMain.Selected = currentValue == TabMain.Name
				end

				if TabMain.Selected and not TabMain.Locked then
					TabMain.UIElements.TabItem.ImageTransparency = TabBackgroundTransparency
					TabMain.UIElements.TabItem.Highlight.ImageTransparency = 0.75
					TabMain.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency = 0
					if TabMain.UIElements.TabIcon then
						TabMain.UIElements.TabIcon.ImageLabel.ImageTransparency = 0
					end
				end

				Dropdown.Tabs[Index] = TabMain
				RowCount = RowCount + 1

				if Type == "Dropdown" then
					Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
						if Dropdown.Locked or TabMain.Locked then
							return
						end

						if Dropdown.Multi then
							if not TabMain.Selected then
								TabMain.Selected = true
								Tween(
									TabMain.UIElements.TabItem,
									0.1,
									{ ImageTransparency = TabBackgroundTransparency }
								):Play()
								Tween(TabMain.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 0.75 }):Play()
								Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
								if TabMain.UIElements.TabIcon then
									Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
								end
								table.insert(Dropdown.Value, TabMain.Original)
							else
								if not Dropdown.AllowNone and #Dropdown.Value == 1 then
									return
								end
								TabMain.Selected = false
								Tween(TabMain.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
								Tween(TabMain.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
								Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0.4 }):Play()
								if TabMain.UIElements.TabIcon then
									Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.2 }):Play()
								end

								for i, v in next, Dropdown.Value do
									if typeof(v) == "table" and (v.Title == TabMain.Name) or (v == TabMain.Name) then
										table.remove(Dropdown.Value, i)
										break
									end
								end
							end
						else
							for Index, TabPisun in next, Dropdown.Tabs do
								Tween(TabPisun.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
								Tween(TabPisun.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 1 }):Play()
								Tween(
									TabPisun.UIElements.TabItem.Frame.Title.TextLabel,
									0.1,
									{ TextTransparency = 0.4 }
								):Play()
								if TabPisun.UIElements.TabIcon then
									Tween(TabPisun.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.2 }):Play()
								end
								TabPisun.Selected = false
							end
							TabMain.Selected = true
							Tween(TabMain.UIElements.TabItem, 0.1, { ImageTransparency = TabBackgroundTransparency }):Play()
							Tween(TabMain.UIElements.TabItem.Highlight, 0.1, { ImageTransparency = 0.75 }):Play()
							Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
							if TabMain.UIElements.TabIcon then
								Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
							end
							Dropdown.Value = TabMain.Original
						end
						Callback()
						if not Dropdown.Multi then
							DropdownModule:Close()
						end
					end)
				elseif Type == "Menu" then
					if not TabMain.Locked then
						Creator.AddSignal(TabMain.UIElements.TabItem.MouseEnter, function()
							Tween(TabMain.UIElements.TabItem, 0.08, { ImageTransparency = TabBackgroundTransparency }):Play()
						end)
						Creator.AddSignal(TabMain.UIElements.TabItem.InputEnded, function()
							Tween(TabMain.UIElements.TabItem, 0.08, { ImageTransparency = 1 }):Play()
						end)
					end
					Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
						if Dropdown.Locked or TabMain.Locked then
							return
						end
						Callback(Tab.Callback or function() end)
						DropdownModule:Close()
					end)
				end
			else
				require("../../elements/Divider"):New({ Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame })
			end
		end

		if RowCount == 0 then
			New("TextLabel", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				Text = "No options",
				TextSize = 15,
				TextTransparency = 0.5,
				ThemeTag = {
					TextColor3 = "Text",
				},
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				Parent = Dropdown.UIElements.Menu.Frame.ScrollingFrame,
				Name = "EmptyState",
			})
		end

		-- Recalculate once for the whole list after the layout settles.
		ScheduleRecalc()

		-- local maxWidth = Dropdown.MenuWidth or 0
		-- if maxWidth == 0 then
		--     for _, tabmain in next, Dropdown.Tabs do
		--         if tabmain.UIElements.TabItem.Frame.UIListLayout then
		--             maxWidth = math.max(maxWidth, tabmain.UIElements.TabItem.Frame.UIListLayout.AbsoluteContentSize.X)
		--         end
		--     end
		-- end

		Dropdown.UIElements.MenuCanvas.Size = UDim2.new(
			0,
			Dropdown.MenuWidth + 6 + 6 + 5 + 5 + 18 + 6 + 6,
			Dropdown.UIElements.MenuCanvas.Size.Y.Scale,
			Dropdown.UIElements.MenuCanvas.Size.Y.Offset
		)

		Dropdown.Values = Values
		if silent then
			DropdownModule:Display()
		else
			Callback()
		end
	end

	function DropdownModule:Select(Items)
		if Items then
			Dropdown.Value = Items
		else
			if Dropdown.Multi then
				Dropdown.Value = {}
			else
				Dropdown.Value = nil
			end
		end

		DropdownModule:Display()

		-- Rebuild row highlighting while the menu is already open so a
		-- programmatic select is reflected immediately.
		if Dropdown.Opened then
			DropdownModule:Refresh(Dropdown.Values, true)
		end
	end
	
	-- Build the rows once, like stock WindUI. Deferring this to the first
	-- click caused empty menus when the click-time build failed.
	DropdownModule:Refresh(Dropdown.Values, true)

	local stateToken = 0

	function DropdownModule:Open()
		stateToken = stateToken + 1
		local token = stateToken

		local Values = ResolveValues(Dropdown.Values)
		local ValueCount = type(Values) == "table" and #Values or -1
		if Values ~= builtValues or ValueCount ~= builtCount then
			DropdownModule:Refresh(Dropdown.Values, true)

			-- Give the menu a usable height before UpdatePosition runs. The
			-- layout signal corrects this with the real content height later.
			RecalculateListSize()
			RecalculateCanvasSize()

			task.spawn(function()
				task.wait()
				RecalculateListSize()
				RecalculateCanvasSize()
			end)
		end

		if not Dropdown.Locked then
			Dropdown.UIElements.Menu.Visible = true
			Dropdown.UIElements.MenuCanvas.Visible = true
			Dropdown.UIElements.MenuCanvas.Active = true
			Dropdown.UIElements.Menu.Size = UDim2.new(1, 0, 0, 0)
			Tween(Dropdown.UIElements.Menu, 0.1, {
				Size = UDim2.new(1, 0, 1, 0),
				ImageTransparency = 0,
			}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()

			task.spawn(function()
				task.wait(0.1)
				if token ~= stateToken or Dropdown.Locked then
					return
				end
				Dropdown.Opened = true
			end)

			UpdatePosition()
		end
	end

	function DropdownModule:Close()
		stateToken = stateToken + 1
		local token = stateToken
		Dropdown.Opened = false

		Tween(Dropdown.UIElements.Menu, 0.25, {
			Size = UDim2.new(1, 0, 0, 0),
			ImageTransparency = 1,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()

		task.spawn(function()
			task.wait(0.1)
			if token ~= stateToken then
				return
			end
			Dropdown.UIElements.Menu.Visible = false
		end)

		task.spawn(function()
			task.wait(0.25)
			if token ~= stateToken then
				return
			end
			Dropdown.UIElements.MenuCanvas.Visible = false
			Dropdown.UIElements.MenuCanvas.Active = false
		end)
	end

	local toggleQueued = false
	local function ToggleDropdown()
		-- A click can reach both the trigger and the parent row. Deduplicate
		-- within the frame without blocking a deliberate second click.
		if toggleQueued then
			return
		end
		toggleQueued = true
		task.defer(function()
			toggleQueued = false
		end)

		if Dropdown.UIElements.MenuCanvas.Visible then
			DropdownModule:Close()
		else
			DropdownModule:Open()
		end
	end

	-- The whole row opens the dropdown, not only the small trigger label.
	-- Both are connected; the cooldown prevents a double toggle when the
	-- click reaches the parent as well.
	Creator.AddSignal(Dropdown.DropdownFrame.UIElements.Main.MouseButton1Click, ToggleDropdown)
	if Dropdown.UIElements.Dropdown then
		Creator.AddSignal(Dropdown.UIElements.Dropdown.MouseButton1Click, ToggleDropdown)
	end

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			local menuCanvas = Dropdown.UIElements.MenuCanvas
			local AbsPos, AbsSize = menuCanvas.AbsolutePosition, menuCanvas.AbsoluteSize

			local DropdownButton = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
			local ButtonAbsPos = DropdownButton.AbsolutePosition
			local ButtonAbsSize = DropdownButton.AbsoluteSize

			local isClickOnDropdown = Mouse.X >= ButtonAbsPos.X
				and Mouse.X <= ButtonAbsPos.X + ButtonAbsSize.X
				and Mouse.Y >= ButtonAbsPos.Y
				and Mouse.Y <= ButtonAbsPos.Y + ButtonAbsSize.Y

			local isClickOnMenu = Mouse.X >= AbsPos.X
				and Mouse.X <= AbsPos.X + AbsSize.X
				and Mouse.Y >= AbsPos.Y
				and Mouse.Y <= AbsPos.Y + AbsSize.Y

			if Config.Window.CanDropdown and Dropdown.Opened and not isClickOnDropdown and not isClickOnMenu then
				DropdownModule:Close()
			end
		end
	end)

	-- AbsoluteContentSize only updates after Roblox runs layout. The first
	-- open builds rows lazily, so recalculating immediately measured zero and
	-- collapsed the menu; react to the layout signal instead.
	Creator.AddSignal(
		Dropdown.UIElements.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),
		ScheduleRecalc
	)

	Creator.AddSignal(
		Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition")
			or Dropdown.DropdownFrame.UIElements.Main:GetPropertyChangedSignal("AbsolutePosition"),
		function()
			-- The trigger moves every frame while its tab scrolls; there is no
			-- reason to recompute the menu position while it is closed.
			if Dropdown.Opened then
				UpdatePosition()
			end
		end
	)

	return DropdownModule
end

return DropdownMenu
