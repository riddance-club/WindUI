local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Creator = require("../../modules/Creator")
local New = Creator.New
local NewRoundFrame = Creator.NewRoundFrame
local Tween = Creator.Tween

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))

local TagModule = require("../ui/Tag")

local function Color3ToHSB(color)
	local r, g, b = color.R, color.G, color.B
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min

	local h = 0
	if delta ~= 0 then
		if max == r then
			h = (g - b) / delta % 6
		elseif max == g then
			h = (b - r) / delta + 2
		else
			h = (r - g) / delta + 4
		end
		h = h * 60
	else
		h = 0
	end

	local s = (max == 0) and 0 or (delta / max)
	local v = max

	return {
		h = math.floor(h + 0.5),
		s = s,
		b = v,
	}
end

local function GetPerceivedBrightness(color)
	local r = color.R
	local g = color.G
	local b = color.B
	return 0.299 * r + 0.587 * g + 0.114 * b
end

local function GetTextColorForHSB(color)
	local hsb = Color3ToHSB(color)
	local h, s, b = hsb.h, hsb.s, hsb.b
	if GetPerceivedBrightness(color) > 0.5 then
		return Color3.fromHSV(h / 360, 0, 0.05)
	else
		return Color3.fromHSV(h / 360, 0, 0.98)
	end
end

return function(Config)
	local Element = {
		Title = Config.Title,
		Desc = Config.Desc or nil,
		Hover = Config.Hover,
		Thumbnail = Config.Thumbnail,
		ThumbnailSize = Config.ThumbnailSize or 80,
		Image = Config.Image,
		IconThemed = Config.IconThemed or false,
		ImageSize = Config.ImageSize or 30,
		Color = Config.Color,
		Scalable = Config.Scalable,
		Parent = Config.Parent,
		Justify = Config.Justify or "Between", -- Center or Between
		UIPadding = Config.Window.ElementConfig.UIPadding,
		UICorner = Config.Window.ElementConfig.UICorner,
		Size = Config.Size or "Default", -- Small, Default, Large
		Tags = Config.Tags or {},
		UIElements = {},

		Index = Config.Index,
	}

	local AddPaddingX = Element.Size == "Small" and -4 or Element.Size == "Large" and 4 or 0
	local AddPaddingY = Element.Size == "Small" and -4 or Element.Size == "Large" and 4 or 0

	local ImageSize = Element.ImageSize
	local ThumbnailSize = Element.ThumbnailSize
	local CanHover = true
	local Hovering = false

	local IconOffset = 0

	local ThumbnailFrame
	local ImageFrame
	if Element.Thumbnail then
		ThumbnailFrame = Creator.Image(
			Element.Thumbnail,
			Element.Title,
			Config.Window.NewElements and Element.UICorner - 11 or (Element.UICorner - 4),
			Config.Window.Folder,
			"Thumbnail",
			false,
			Element.IconThemed
		)
		ThumbnailFrame.Size = UDim2.new(1, 0, 0, ThumbnailSize)
	end
	if Element.Image then
		ImageFrame = Creator.Image(
			Element.Image,
			Element.Title,
			Config.Window.NewElements and Element.UICorner - 11 or (Element.UICorner - 4),
			Config.Window.Folder,
			"Image",
			Element.IconThemed,
			not Element.Color and true or false,
			"ElementIcon"
		)
		--print(Creator.Colors[Element.Color])
		if typeof(Element.Color) == "string" and not string.find(Element.Image, "rbxthumb") then
			ImageFrame.ImageLabel.ImageColor3 = GetTextColorForHSB(Color3.fromHex(Creator.Colors[Element.Color]))
		elseif typeof(Element.Color) == "Color3" and not string.find(Element.Image, "rbxthumb") then
			ImageFrame.ImageLabel.ImageColor3 = GetTextColorForHSB(Element.Color)
		end

		ImageFrame.Size = UDim2.new(0, ImageSize, 0, ImageSize)

		IconOffset = ImageSize
	end

	local function CreateText(Title, Type)
		local TextColor = typeof(Element.Color) == "string"
				and GetTextColorForHSB(Color3.fromHex(Creator.Colors[Element.Color]))
			or typeof(Element.Color) == "Color3" and GetTextColorForHSB(Element.Color)

		return New("TextLabel", {
			BackgroundTransparency = 1,
			Text = Title or "",
			TextSize = Type == "Desc" and 15 or 17,
			TextXAlignment = "Left",
			ThemeTag = {
				TextColor3 = not Element.Color and ("Element" .. Type) or nil,
			},
			TextColor3 = Element.Color and TextColor or nil,
			TextTransparency = Type == "Desc" and 0.3 or 0,
			TextWrapped = true,
			Size = UDim2.new(Element.Justify == "Between" and 1 or 0, 0, 0, 0),
			AutomaticSize = Element.Justify == "Between" and "Y" or "XY",
			FontFace = Font.new(Creator.Font, Type == "Desc" and Enum.FontWeight.Medium or Enum.FontWeight.SemiBold),
		})
	end

	local Title = CreateText(Element.Title, "Title")
	local Desc
	if Element.Desc and Element.Desc ~= "" then
		Desc = CreateText(Element.Desc, "Desc")
	end
	if Desc and (not Element.Title or Element.Title == "") then
		Desc.Visible = false
	end

	Element.UIElements.Title = Title
	Element.UIElements.Desc = Desc

	local TitleContent
	local function BindDesc()
		if not Desc or not Config.ElementTable then
			return
		end
		Creator.AddSignal(Desc:GetPropertyChangedSignal("Text"), function()
			if Element.Desc ~= Desc.Text then
				Element:SetDesc(Desc.Text)
				Config.ElementTable.Desc = Desc.Text
			end
		end)
	end

	local function EnsureDesc()
		if Desc then
			return Desc
		end
		Desc = CreateText("", "Desc")
		Desc.Parent = TitleContent
		Element.UIElements.Desc = Desc
		BindDesc()
		return Desc
	end

	Element.UIElements.Container = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = "Y",
		BackgroundTransparency = 1,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, Element.UIPadding),
			FillDirection = "Vertical",
			VerticalAlignment = "Center",
			HorizontalAlignment = Element.Justify == "Between" and "Left" or "Center",
		}),
		ThumbnailFrame,
		New("Frame", {
			Size = UDim2.new(
				Element.Justify == "Between" and 1 or 0,
				Element.Justify == "Between" and -Config.TextOffset or 0,
				0,
				0
			),
			AutomaticSize = Element.Justify == "Between" and "Y" or "XY",
			BackgroundTransparency = 1,
			Name = "TitleFrame",
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0, Element.UIPadding),
				FillDirection = "Horizontal",
				VerticalAlignment = Config.Window.NewElements and (Element.Justify == "Between" and "Top" or "Center")
					or "Center",
				HorizontalAlignment = Element.Justify ~= "Between" and Element.Justify or "Center",
			}),
			ImageFrame,
			TitleContent,
		}),
	})

	TitleContent = New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Element.Justify == "Between" and "Y" or "XY",
		Size = UDim2.new(
			Element.Justify == "Between" and 1 or 0,
			Element.Justify == "Between" and (ImageFrame and -IconOffset - Element.UIPadding or -IconOffset) or 0,
			1,
			0
		),
		Name = "TitleFrame",
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, (Config.Window.NewElements and Element.UIPadding / 2 or 0) + AddPaddingY),
			PaddingLeft = UDim.new(0, (Config.Window.NewElements and Element.UIPadding / 2 or 0) + AddPaddingX),
			PaddingRight = UDim.new(0, (Config.Window.NewElements and Element.UIPadding / 2 or 0) + AddPaddingX),
			PaddingBottom = UDim.new(0, (Config.Window.NewElements and Element.UIPadding / 2 or 0) + AddPaddingY),
		}),
		New("UIListLayout", {
			Padding = UDim.new(0, 6),
			FillDirection = "Vertical",
			VerticalAlignment = "Center",
			HorizontalAlignment = "Left",
		}),
		Title,
		Desc,
	})
	TitleContent.Parent = Element.UIElements.Container.TitleFrame

	local Tags = Config.Tags
	if Tags and #Tags > 0 then
		local TagsFrame = New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = "Y",
			LayoutOrder = -99,
			BackgroundTransparency = 1,
			ScrollingDirection = "X",
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 0,
		}, {
			New("UIListLayout", {
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
				HorizontalAlignment = "Left",
				Padding = UDim.new(0, Config.Window.UIPadding / 2),
			}),
		})
		TagsFrame.Parent = TitleContent

		New("Frame", {
			Name = "Space",
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = -98,
			Parent = TitleContent,
		})

		for _, TagConfig in next, Tags do
			TagModule:New(TagConfig, TagsFrame)
		end

		Creator.AddSignal(TagsFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			TagsFrame.Size = UDim2.new(
				1,
				0,
				0,
				TagsFrame.UIListLayout.AbsoluteContentSize.Y / Config.ParentConfig.UIScale
			)
		end)
	end

	BindDesc()

	-- print(Config.Tab.Elements)
	-- print(Config.Index)
	-- print("Squircle")

	local Main, MainTable = NewRoundFrame(Element.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = "Y",
		ImageTransparency = Element.Color and 0.05 or (not Config.Window.NewElements and 0.93 or nil),
		Parent = Config.Parent,
		ThemeTag = {
			ImageColor3 = not Element.Color and (Config.Window.NewElements and "ElementBackground" or "Text") or nil,
			ImageTransparency = not Element.Color
					and (Config.Window.NewElements and "ElementBackgroundTransparency" or nil)
				or nil,
		},
		ImageColor3 = Element.Color and (typeof(Element.Color) == "string" and Color3.fromHex(
			Creator.Colors[Element.Color]
		) or typeof(Element.Color) == "Color3" and Element.Color) or nil,
	}, {
		Element.UIElements.Container,
		New("UIPadding", {
			PaddingTop = UDim.new(0, Element.UIPadding),
			PaddingLeft = UDim.new(0, Element.UIPadding),
			PaddingRight = UDim.new(0, Element.UIPadding),
			PaddingBottom = UDim.new(0, Element.UIPadding),
		}),
	}, true, true)

	Element.UIElements.Main = Main

	-- Flat hover: one squircle overlay that fades in. The old implementation
	-- built two extra shape layers with animated gradient sweeps for every row.
	local Hover, HoverTable
	if Element.Hover then
		Hover, HoverTable = NewRoundFrame(Element.UICorner, MainTable:GetType(), {
			Size = UDim2.new(1, Element.UIPadding * 2, 1, Element.UIPadding * 2),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1,
			Active = false,
			ZIndex = 3,
			ThemeTag = {
				ImageColor3 = "Text",
			},
			Parent = Main,
		}, nil, true)

		Creator.AddSignal(Main.MouseEnter, function()
			if CanHover then
				Tween(Hover, 0.12, { ImageTransparency = 0.95 }):Play()
			end
		end)
		Creator.AddSignal(Main.InputEnded, function()
			if CanHover then
				Tween(Hover, 0.12, { ImageTransparency = 1 }):Play()
			end
		end)
	end

	-- Lock and highlight layers are only built when they are actually used
	-- (most elements are never locked or scrolled to).
	local Locked, LockedTable, LockedTitle
	local function EnsureLocked()
		if Locked then
			return Locked
		end

		local LockedIcon = Creator.Image("lock", "lock", 0, Config.Window.Folder, "Lock", false)
		LockedIcon.Size = UDim2.new(0, 20, 0, 20)
		LockedIcon.ImageLabel.ImageColor3 = Color3.new(1, 1, 1)
		LockedIcon.ImageLabel.ImageTransparency = 0.4

		LockedTitle = New("TextLabel", {
			Text = "Locked",
			TextSize = 18,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			AutomaticSize = "XY",
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.05,
		})

		Locked, LockedTable = NewRoundFrame(Element.UICorner, MainTable:GetType(), {
			Size = UDim2.new(1, Element.UIPadding * 2, 1, Element.UIPadding * 2),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 0.25,
			ImageColor3 = Color3.new(0, 0, 0),
			Visible = false,
			Active = false,
			ZIndex = 9999999,
			Parent = Main,
		}, {
			New("UIListLayout", {
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
				HorizontalAlignment = "Center",
				Padding = UDim.new(0, 8),
			}),
			LockedIcon,
			LockedTitle,
		}, nil, true)

		Element.UIElements.Locked = Locked
		return Locked
	end

	local Highlight, HighlightTable
	local function EnsureHighlight()
		if Highlight then
			return Highlight
		end

		Highlight, HighlightTable = NewRoundFrame(Element.UICorner, MainTable:GetType(), {
			Size = UDim2.new(1, Element.UIPadding * 2, 1, Element.UIPadding * 2),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1,
			Active = false,
			ZIndex = 4,
			ThemeTag = {
				ImageColor3 = "Text",
			},
			Parent = Main,
		}, nil, true)

		return Highlight
	end

	function Element:SetTitle(text)
		Element.Title = text
		Title.Text = text
	end

	function Element:SetDesc(text)
		Element.Desc = text
		if not text then
			if Desc then
				Desc.Visible = false
			end
			return
		end

		local Label = EnsureDesc()
		Label.Text = text
		Label.Visible = true
	end

	function Element:Colorize(obj, prop)
		if Element.Color then
			obj[prop] = typeof(Element.Color) == "string"
					and GetTextColorForHSB(Color3.fromHex(Creator.Colors[Element.Color]))
				or typeof(Element.Color) == "Color3" and GetTextColorForHSB(Element.Color)
				or nil
		end
	end

	if Config.ElementTable then
		Creator.AddSignal(Title:GetPropertyChangedSignal("Text"), function()
			if Element.Title ~= Title.Text then
				Element:SetTitle(Title.Text)
				Config.ElementTable.Title = Title.Text
			end
		end)
		BindDesc()
	end

	-- function Element:Show()

	-- end

	function Element:SetThumbnail(newThumbnail, newSize)
		Element.Thumbnail = newThumbnail
		if newSize then
			Element.ThumbnailSize = newSize
			ThumbnailSize = newSize
		end

		if ThumbnailFrame then
			if newThumbnail then
				ThumbnailFrame:Destroy()
				ThumbnailFrame = Creator.Image(
					newThumbnail,
					Element.Title,
					Element.UICorner - 3,
					Config.Window.Folder,
					"Thumbnail",
					false,
					Element.IconThemed
				)
				if ThumbnailFrame then
					ThumbnailFrame.Size = UDim2.new(1, 0, 0, ThumbnailSize)
					ThumbnailFrame.Parent = Element.UIElements.Container
					local layout = Element.UIElements.Container:FindFirstChild("UIListLayout")
					if layout then
						ThumbnailFrame.LayoutOrder = -1
					end
				end
			else
				ThumbnailFrame.Visible = false
			end
		else
			if newThumbnail then
				ThumbnailFrame = Creator.Image(
					newThumbnail,
					Element.Title,
					Element.UICorner - 3,
					Config.Window.Folder,
					"Thumbnail",
					false,
					Element.IconThemed
				)
				if ThumbnailFrame then
					ThumbnailFrame.Size = UDim2.new(1, 0, 0, ThumbnailSize)
					ThumbnailFrame.Parent = Element.UIElements.Container
					local layout = Element.UIElements.Container:FindFirstChild("UIListLayout")
					if layout then
						ThumbnailFrame.LayoutOrder = -1
					end
				end
			end
		end
	end

	function Element:SetImage(newImage, newSize)
		Element.Image = newImage
		if newSize then
			Element.ImageSize = newSize
			ImageSize = newSize
		end

		if newImage then
			local OldImageParent = ImageFrame and ImageFrame.Parent or Element.UIElements.Container.TitleFrame
			if ImageFrame then
				ImageFrame:Destroy()
			end

			ImageFrame = Creator.Image(
				newImage,
				newImage,
				Element.UICorner - 3,
				Config.Window.Folder,
				"Image",
				not Element.Color and true or false
			)
			if ImageFrame then
				if typeof(Element.Color) == "string" and not string.find(Element.Image, "rbxthumb") then
					ImageFrame.ImageLabel.ImageColor3 =
						GetTextColorForHSB(Color3.fromHex(Creator.Colors[Element.Color]))
				elseif typeof(Element.Color) == "Color3" and not string.find(Element.Image, "rbxthumb") then
					ImageFrame.ImageLabel.ImageColor3 = GetTextColorForHSB(Element.Color)
				end

				ImageFrame.Visible = true
				ImageFrame.Parent = OldImageParent
				ImageFrame.LayoutOrder = -99

				ImageFrame.Size = UDim2.new(0, ImageSize, 0, ImageSize)
				IconOffset = Element.ImageSize + Element.UIPadding
			end
		else
			if ImageFrame then
				ImageFrame.Visible = true
			end
			IconOffset = 0
		end

		Element.UIElements.Container.TitleFrame.TitleFrame.Size = UDim2.new(1, -IconOffset, 1, 0)
	end

	function Element:Destroy()
		Main:Destroy()
	end

	function Element:Lock(newtitle)
		CanHover = false
		local Overlay = EnsureLocked()
		Overlay.Active = true
		Overlay.Visible = true
		LockedTitle.Text = newtitle or "Locked"
	end

	function Element:Unlock()
		CanHover = true
		if Locked then
			Locked.Active = false
			Locked.Visible = false
		end
	end

	function Element:Highlight()
		local Overlay = EnsureHighlight()
		Overlay.ImageTransparency = 0.8
		Tween(Overlay, 0.45, { ImageTransparency = 1 }):Play()
	end

	function Element.UpdateShape(Tab)
		if Config.Window.NewElements then
			local newShape = Creator:GetElementPosition(
				Tab.Elements,
				Element.Index,
				Config.ParentConfig.ParentTable.__type == "HStack" or Config.ParentConfig.ParentTable.__type == "Group"
			)

			if newShape and Main then
				MainTable:SetType(newShape)
				if HoverTable then
					HoverTable:SetType(newShape)
				end
				if LockedTable then
					LockedTable:SetType(newShape)
				end
				if HighlightTable then
					HighlightTable:SetType(newShape)
				end
			end
		end
	end

	--task.wait(.015)

	--Element:Show()

	return Element
end
