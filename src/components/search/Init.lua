local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))

local SearchBar = {
	Margin = 8,
	Padding = 9,
}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

function SearchBar.new(TabModule, Parent, OnClose)
	local SearchBarModule = {
		IconSize = 18,
		Padding = 14,
		Radius = 22,
		Width = 400,
		MaxHeight = 380,

		Icons = require("./Icons"),
	}

	local currentSearchId = 0

	local TextBox = New("TextBox", {
		Text = "",
		PlaceholderText = "Search...",
		ThemeTag = {
			PlaceholderColor3 = "Placeholder",
			TextColor3 = "Text",
		},
		Size = UDim2.new(1, -((SearchBarModule.IconSize * 2) + (SearchBarModule.Padding * 2)), 0, 0),
		AutomaticSize = "Y",
		ClipsDescendants = true,
		ClearTextOnFocus = false,
		BackgroundTransparency = 1,
		TextXAlignment = "Left",
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
		TextSize = 18,
	})

	local CloseButton = New("ImageLabel", {
		Image = Creator.Icon("x")[1],
		ImageRectSize = Creator.Icon("x")[2].ImageRectSize,
		ImageRectOffset = Creator.Icon("x")[2].ImageRectPosition,
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "Icon",
		},
		ImageTransparency = 0.1,
		Size = UDim2.new(0, SearchBarModule.IconSize, 0, SearchBarModule.IconSize),
	}, {
		New("TextButton", {
			Size = UDim2.new(1, 8, 1, 8),
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 999999999,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Text = "",
		}),
	})

	local ScrollingFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticCanvasSize = "Y",
		ScrollingDirection = "Y",
		ElasticBehavior = "Never",
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 0),
			FillDirection = "Vertical",
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, SearchBarModule.Padding),
			PaddingLeft = UDim.new(0, SearchBarModule.Padding),
			PaddingRight = UDim.new(0, SearchBarModule.Padding),
			PaddingBottom = UDim.new(0, SearchBarModule.Padding),
		}),
	})

	local SearchFrame = Creator.NewRoundFrame(SearchBarModule.Radius, "Squircle", {
		Size = UDim2.new(1, 0, 1, 0),
		ThemeTag = {
			ImageColor3 = "WindowSearchBarBackground",
		},
		ImageTransparency = 0,
	}, {
		Creator.NewRoundFrame(SearchBarModule.Radius, "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			ThemeTag = {
				ImageColor3 = "White",
			},
			ImageTransparency = 1,
			Name = "Frame",
		}, {
			New("Frame", {
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundTransparency = 1,
			}, {
				New("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
				}, {
					New("ImageLabel", {
						Image = Creator.Icon("search")[1],
						ImageRectSize = Creator.Icon("search")[2].ImageRectSize,
						ImageRectOffset = Creator.Icon("search")[2].ImageRectPosition,
						BackgroundTransparency = 1,
						ThemeTag = {
							ImageColor3 = "Icon",
						},
						ImageTransparency = 0.1,
						Size = UDim2.new(0, SearchBarModule.IconSize, 0, SearchBarModule.IconSize),
					}),
					TextBox,
					CloseButton,
					New("UIListLayout", {
						Padding = UDim.new(0, SearchBarModule.Padding),
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					}),
					New("UIPadding", {
						PaddingLeft = UDim.new(0, SearchBarModule.Padding),
						PaddingRight = UDim.new(0, SearchBarModule.Padding),
					}),
				}),
			}),
			New("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = "Y",
				Size = UDim2.new(1, 0, 0, 0),
				Name = "Results",
			}, {
				New("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					ThemeTag = {
						BackgroundColor3 = "Outline",
					},
					BackgroundTransparency = 0.9,
					Visible = false,
				}),
				ScrollingFrame,
				New("UISizeConstraint", {
					MaxSize = Vector2.new(SearchBarModule.Width, SearchBarModule.MaxHeight),
				}),
			}),
			New("UIListLayout", {
				Padding = UDim.new(0, 0),
				FillDirection = "Vertical",
			}),
		}),
	})

	local SearchFrameContainer = New("Frame", {
		Size = UDim2.new(0, SearchBarModule.Width, 0, 0),
		AutomaticSize = "Y",
		Parent = Parent,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		ZIndex = 99999999,
	}, {
		New("UIScale", {
			Scale = 0.9,
		}),
		SearchFrame,
	})

	local function CreateSearchTab(Title, Desc, Icon, TargetParent, IsParent, Callback)
		local Tab = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			Parent = TargetParent or nil,
		}, {
			Creator.NewRoundFrame(SearchBarModule.Radius - 11, "Squircle", {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ThemeTag = {
					ImageColor3 = "Text",
				},
				ImageTransparency = 1,
				Name = "Main",
			}, {
				Creator.NewRoundFrame(SearchBarModule.Radius - 11, "Glass-1", {
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ThemeTag = {
						ImageColor3 = "White",
					},
					ImageTransparency = 1,
					Name = "Outline",
				}, {
					New("UIPadding", {
						PaddingTop = UDim.new(0, SearchBarModule.Padding - 2),
						PaddingLeft = UDim.new(0, SearchBarModule.Padding),
						PaddingRight = UDim.new(0, SearchBarModule.Padding),
						PaddingBottom = UDim.new(0, SearchBarModule.Padding - 2),
					}),
					New("ImageLabel", {
						Image = Creator.Icon(Icon)[1],
						ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
						ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
						BackgroundTransparency = 1,
						ThemeTag = {
							ImageColor3 = "Icon",
						},
						ImageTransparency = 0.1,
						Size = UDim2.new(0, SearchBarModule.IconSize, 0, SearchBarModule.IconSize),
					}),
					New("Frame", {
						Size = UDim2.new(1, -SearchBarModule.IconSize - SearchBarModule.Padding, 0, 0),
						BackgroundTransparency = 1,
					}, {
						New("TextLabel", {
							Text = Title,
							ThemeTag = {
								TextColor3 = "Text",
							},
							TextSize = 17,
							BackgroundTransparency = 1,
							TextXAlignment = "Left",
							FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
							Size = UDim2.new(1, 0, 0, 0),
							TextTruncate = "AtEnd",
							AutomaticSize = "Y",
							Name = "Title",
						}),
						New("TextLabel", {
							Text = Desc or "",
							Visible = Desc and true or false,
							ThemeTag = {
								TextColor3 = "Text",
							},
							TextSize = 15,
							TextTransparency = 0.3,
							BackgroundTransparency = 1,
							TextXAlignment = "Left",
							FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
							Size = UDim2.new(1, 0, 0, 0),
							TextTruncate = "AtEnd",
							AutomaticSize = "Y",
							Name = "Desc",
						}) or nil,
						New("UIListLayout", {
							Padding = UDim.new(0, 6),
							FillDirection = "Vertical",
						}),
					}),
					New("UIListLayout", {
						Padding = UDim.new(0, SearchBarModule.Padding),
						FillDirection = "Horizontal",
					}),
				}),
			}, true),
			New("Frame", {
				Name = "ParentContainer",
				Size = UDim2.new(1, -SearchBarModule.Padding, 0, 0),
				AutomaticSize = "Y",
				BackgroundTransparency = 1,
				Visible = IsParent,
			}, {
				Creator.NewRoundFrame(99, "Squircle", {
					Size = UDim2.new(0, 2, 1, 0),
					BackgroundTransparency = 1,
					ThemeTag = {
						ImageColor3 = "Text",
					},
					ImageTransparency = 0.9,
				}),
				New("Frame", {
					Size = UDim2.new(1, -SearchBarModule.Padding - 2, 0, 0),
					Position = UDim2.new(0, SearchBarModule.Padding + 2, 0, 0),
					BackgroundTransparency = 1,
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0, 0),
						FillDirection = "Vertical",
					}),
				}),
			}),
			New("UIListLayout", {
				Padding = UDim.new(0, 0),
				FillDirection = "Vertical",
				HorizontalAlignment = "Right",
			}),
		})

		Tab.Main.Size = UDim2.new(
			1,
			0,
			0,
			Tab.Main.Outline.Frame.Desc.Visible
					and (((SearchBarModule.Padding - 2) * 2) + Tab.Main.Outline.Frame.Title.TextBounds.Y + 6 + Tab.Main.Outline.Frame.Desc.TextBounds.Y)
				or (((SearchBarModule.Padding - 2) * 2) + Tab.Main.Outline.Frame.Title.TextBounds.Y)
		)

		Creator.AddSignal(Tab.Main.MouseEnter, function()
			Tween(Tab.Main, 0.04, { ImageTransparency = 0.95 }):Play()
		end)
		Creator.AddSignal(Tab.Main.InputEnded, function()
			Tween(Tab.Main, 0.08, { ImageTransparency = 1 }):Play()
		end)
		Creator.AddSignal(Tab.Main.MouseButton1Click, function()
			if Callback then
				Callback()
			end
		end)

		return Tab
	end

	local function CalculateElementScore(elem, queryLower, isKeySearch)
		local title = elem.Title and string.lower(elem.Title) or ""
		local desc = elem.Desc and string.lower(elem.Desc) or ""
		local score = 0

		if title == queryLower then
			score += 100
		elseif string.sub(title, 1, #queryLower) == queryLower then
			score += 60
		elseif string.find(title, queryLower, 1, true) then
			score += 40
		end

		if desc ~= "" and string.find(desc, queryLower, 1, true) then
			score += 15
		end

		if score == 0 then
			return 0
		end

		if elem.__type == "Toggle" or elem.__type == "Button" then
			score += (isKeySearch and 0 or 25)
		elseif elem.__type == "Slider" or elem.__type == "Dropdown" or elem.__type == "Colorpicker" or elem.__type == "Input" then
			score += (isKeySearch and 0 or 20)
		elseif elem.__type == "Keybind" then
			if isKeySearch then
				score += 30
			else
				score -= 15
			end
		end

		return score
	end

	local function Search(query)
		if not query or query == "" then
			return {}
		end

		local queryLower = string.lower(query)
		local isKeySearch = string.find(queryLower, "key", 1, true) ~= nil or string.find(queryLower, "bind", 1, true) ~= nil

		local results = {}
		for tabindex, tab in next, TabModule.Tabs do
			local tabTitleLower = tab.Title and string.lower(tab.Title) or ""
			local tabMatches = tabTitleLower ~= "" and string.find(tabTitleLower, queryLower, 1, true) ~= nil
			local elementResults = {}

			for elemindex, elem in next, tab.Elements do
				if elem.__type ~= "Section" and elem.__type ~= "Divider" and elem.__type ~= "Space" then
					local score = CalculateElementScore(elem, queryLower, isKeySearch)
					if score > 0 then
						table.insert(elementResults, {
							Title = elem.Title,
							Desc = elem.Desc,
							Original = elem,
							__type = elem.__type,
							Index = elemindex,
							Score = score,
						})
					end
				end
			end

			table.sort(elementResults, function(a, b)
				return a.Score > b.Score
			end)

			if tabMatches or #elementResults > 0 then
				table.insert(results, {
					Tab = tab,
					TabIndex = tabindex,
					Title = tab.Title,
					Icon = tab.Icon,
					Elements = elementResults,
					Score = (#elementResults > 0 and elementResults[1].Score or 0) + (tabMatches and 50 or 0),
				})
			end
		end

		table.sort(results, function(a, b)
			return a.Score > b.Score
		end)

		return results
	end

	local resizeDebounce = false
	Creator.AddSignal(ScrollingFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if resizeDebounce then return end
		resizeDebounce = true
		task.defer(function()
			resizeDebounce = false
			local targetHeight = math.clamp(
				ScrollingFrame.UIListLayout.AbsoluteContentSize.Y + (SearchBarModule.Padding * 2),
				0,
				SearchBarModule.MaxHeight
			)
			Tween(ScrollingFrame, 0.06, {
				Size = UDim2.new(1, 0, 0, targetHeight),
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
		end)
	end)

	function SearchBarModule:Open()
		task.spawn(function()
			SearchFrame.Frame.Visible = true
			SearchFrameContainer.Visible = true
			Tween(SearchFrameContainer.UIScale, 0.12, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end)
	end

	function SearchBarModule:Close(IsDestroy)
		task.spawn(function()
			OnClose()
			SearchFrame.Frame.Visible = false
			Tween(SearchFrameContainer.UIScale, 0.12, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

			task.wait(0.12)
			SearchFrameContainer.Visible = false
			if IsDestroy then
				SearchFrameContainer:Destroy()
			end
		end)
	end

	Creator.AddSignal(CloseButton.TextButton.MouseButton1Click, function()
		SearchBarModule:Close(true)
	end)

	SearchBarModule:Open()

	function SearchBarModule:Search(query)
		query = query or ""

		currentSearchId += 1
		local thisSearchId = currentSearchId

		task.spawn(function()
			local result = Search(query)
			if thisSearchId ~= currentSearchId then return end

			ScrollingFrame.Visible = true
			SearchFrame.Frame.Results.Frame.Visible = true

			for _, item in next, ScrollingFrame:GetChildren() do
				if item.ClassName ~= "UIListLayout" and item.ClassName ~= "UIPadding" then
					item:Destroy()
				end
			end

			if result and #result > 0 then
				for _, i in ipairs(result) do
					if thisSearchId ~= currentSearchId then return end

					local TabIcon = SearchBarModule.Icons["Tab"]
					local TabMainElement = CreateSearchTab(i.Title, nil, TabIcon, ScrollingFrame, true, function()
						SearchBarModule:Close()
						TabModule:SelectTab(i.TabIndex)
					end)

					task.wait()
					if thisSearchId ~= currentSearchId then return end

					if i.Elements and #i.Elements > 0 then
						local containerFrame = TabMainElement:FindFirstChild("ParentContainer") 
							and TabMainElement.ParentContainer.Frame

						for _, e in ipairs(i.Elements) do
							if thisSearchId ~= currentSearchId then return end

							local ElementIcon = SearchBarModule.Icons[e.__type] or SearchBarModule.Icons["Button"]
							CreateSearchTab(
								e.Title,
								e.Desc,
								ElementIcon,
								containerFrame,
								false,
								function()
									SearchBarModule:Close()
									TabModule:SelectTab(i.TabIndex)
									if i.Tab.ScrollToTheElement then
										i.Tab:ScrollToTheElement(e.Index)
									end
								end
							)

							task.wait()
							if thisSearchId ~= currentSearchId then return end
						end
					end
				end
			elseif query ~= "" then
				New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 70),
					Text = "No results found",
					TextSize = 16,
					ThemeTag = {
						TextColor3 = "Text",
					},
					TextTransparency = 0.2,
					BackgroundTransparency = 1,
					FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
					Parent = ScrollingFrame,
					Name = "NotFound",
				})
			else
				ScrollingFrame.Visible = false
				SearchFrame.Frame.Results.Frame.Visible = false
			end
		end)
	end

	Creator.AddSignal(TextBox:GetPropertyChangedSignal("Text"), function()
		SearchBarModule:Search(TextBox.Text)
	end)

	return SearchBarModule
end

return SearchBar
