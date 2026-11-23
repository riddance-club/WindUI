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

local Query = require("./Query")

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

	local CloseIconData = Creator.Icon("x")
	local CloseButton = New("ImageLabel", {
		Image = CloseIconData and CloseIconData[1],
		ImageRectSize = CloseIconData and CloseIconData[2] and CloseIconData[2].ImageRectSize,
		ImageRectOffset = CloseIconData and CloseIconData[2] and CloseIconData[2].ImageRectPosition,
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

	local SearchIconData = Creator.Icon("search")
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
						Image = SearchIconData and SearchIconData[1],
						ImageRectSize = SearchIconData and SearchIconData[2] and SearchIconData[2].ImageRectSize,
						ImageRectOffset = SearchIconData and SearchIconData[2] and SearchIconData[2].ImageRectPosition,
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
		local TabIconData = Creator.Icon(Icon)
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
				Creator.NewRoundFrame(SearchBarModule.Radius - 11, "SquircleOutline", {
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
						Image = TabIconData and TabIconData[1],
						ImageRectSize = TabIconData and TabIconData[2] and TabIconData[2].ImageRectSize,
						ImageRectOffset = TabIconData and TabIconData[2] and TabIconData[2].ImageRectPosition,
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

	local searchDebounceThread

	function SearchBarModule:Search(query)
		query = query or ""

		currentSearchId += 1
		local thisSearchId = currentSearchId

		-- Debounce: while the user is typing, only the last query needs to run.
		if searchDebounceThread and coroutine.status(searchDebounceThread) == "suspended" then
			task.cancel(searchDebounceThread)
		end

		searchDebounceThread = task.delay(0.08, function()
			if thisSearchId ~= currentSearchId then return end

			local result = Query.Find(TabModule, query)
			if thisSearchId ~= currentSearchId then return end

			ScrollingFrame.Visible = true
			SearchFrame.Frame.Results.Frame.Visible = true

			for _, item in next, ScrollingFrame:GetChildren() do
				if item.ClassName ~= "UIListLayout" and item.ClassName ~= "UIPadding" then
					item:Destroy()
				end
			end

			if result and #result > 0 then
				local Rendered = 0
				for _, i in ipairs(result) do
					if thisSearchId ~= currentSearchId then return end

					local TabIcon = SearchBarModule.Icons["Tab"]
					local TabMainElement = CreateSearchTab(i.Title, nil, TabIcon, ScrollingFrame, true, function()
						SearchBarModule:Close()
						TabModule:SelectTab(i.TabIndex)
					end)

					Rendered = Rendered + 1
					if Rendered % 25 == 0 then
						task.wait()
						if thisSearchId ~= currentSearchId then return end
					end

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

									-- Pass the element itself: nested elements live in
									-- Section/Group tables and their local index does not
									-- address Tab.Elements.
									local function RevealElement()
										if i.Tab.ScrollToTheElement then
											i.Tab:ScrollToTheElement(e.Original)
										elseif e.Original and e.Original.ScrollTo then
											e.Original:ScrollTo()
										end
									end

									-- A result inside a collapsed Section needs its
									-- ancestors expanded first, otherwise scrolling lands
									-- on a clipped frame.
									local OpenedSection = false
									for _, ancestor in ipairs(e.Ancestors or {}) do
										if ancestor.Open and not ancestor.Opened then
											ancestor:Open()
											OpenedSection = true
										end
									end

									if OpenedSection then
										task.delay(0.35, RevealElement)
									else
										RevealElement()
									end
								end
							)

							Rendered = Rendered + 1
							if Rendered % 25 == 0 then
								task.wait()
								if thisSearchId ~= currentSearchId then return end
							end
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
