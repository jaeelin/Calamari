local SafetyChecker = { 
	Options = {}, 
	Folder = "Safety Checker",
	Version = "1.0.0",
	GetService = function(Service: string)
		return cloneref and cloneref(game:GetService(Service)) or game:GetService(Service)
	end
}

local Players = SafetyChecker.GetService("Players")
local RunService = SafetyChecker.GetService("RunService")
local ContentProvider = SafetyChecker.GetService("ContentProvider")
local UserInputService = SafetyChecker.GetService("UserInputService")
local TweenService = SafetyChecker.GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local IsStudio = RunService:IsStudio()

local WindowState

local Unloaded = false
local UnloadCallback

local CurrentTheme = "Calamari"
local ThemedElements = {}
local ThemedCallbacks = {}

local Themes = {
	Calamari = {
		Core = Color3.fromRGB(12, 10, 20),
		Divider = Color3.fromRGB(200, 180, 255),
		Text = Color3.fromRGB(235, 225, 255),
		Placeholder = Color3.fromRGB(170, 155, 210),
		DropdownImage = Color3.fromRGB(200, 180, 255),
		DropdownIndicator = Color3.fromRGB(220, 205, 255),
		Global = Color3.fromRGB(220, 205, 255),
		Dragger = Color3.fromRGB(200, 180, 255),
		TabImage = Color3.fromRGB(200, 180, 255),
		TabName = Color3.fromRGB(220, 205, 255),
		Dialogue = Color3.fromRGB(35, 25, 55),
		Toggle = Color3.fromRGB(200, 180, 255),
		Slider = Color3.fromRGB(200, 180, 255)
	},
	
	["French Exit"] = {
		Core = Color3.fromRGB(28, 20, 32),
		Divider = Color3.fromRGB(215, 110, 140),
		Text = Color3.fromRGB(255, 248, 238),
		Placeholder = Color3.fromRGB(190, 160, 170),
		DropdownImage = Color3.fromRGB(215, 110, 140),
		DropdownIndicator = Color3.fromRGB(240, 180, 200),
		Global = Color3.fromRGB(240, 180, 200),
		Dragger = Color3.fromRGB(215, 110, 140),
		TabImage = Color3.fromRGB(215, 110, 140),
		TabName = Color3.fromRGB(255, 230, 220),
		Dialogue = Color3.fromRGB(55, 30, 45),
		Toggle = Color3.fromRGB(225, 120, 155),
		Slider = Color3.fromRGB(215, 110, 140)
	},

	["Who Really Cares"] = {
		Core = Color3.fromRGB(35, 15, 18),
		Divider = Color3.fromRGB(220, 35, 55),
		Text = Color3.fromRGB(255, 245, 240),
		Placeholder = Color3.fromRGB(190, 130, 140),
		DropdownImage = Color3.fromRGB(220, 35, 55),
		DropdownIndicator = Color3.fromRGB(60, 120, 220),
		Global = Color3.fromRGB(60, 120, 220),
		Dragger = Color3.fromRGB(220, 35, 55),
		TabImage = Color3.fromRGB(220, 35, 55),
		TabName = Color3.fromRGB(255, 220, 215),
		Dialogue = Color3.fromRGB(55, 20, 25),
		Toggle = Color3.fromRGB(230, 45, 65),
		Slider = Color3.fromRGB(60, 120, 220)
	},

	["The Night in Question"] = {
		Core = Color3.fromRGB(12, 14, 22),
		Divider = Color3.fromRGB(120, 150, 255),
		Text = Color3.fromRGB(235, 240, 255),
		Placeholder = Color3.fromRGB(140, 150, 185),
		DropdownImage = Color3.fromRGB(120, 150, 255),
		DropdownIndicator = Color3.fromRGB(180, 200, 255),
		Global = Color3.fromRGB(180, 200, 255),
		Dragger = Color3.fromRGB(120, 150, 255),
		TabImage = Color3.fromRGB(120, 150, 255),
		TabName = Color3.fromRGB(220, 230, 255),
		Dialogue = Color3.fromRGB(22, 28, 45),
		Toggle = Color3.fromRGB(140, 170, 255),
		Slider = Color3.fromRGB(120, 150, 255)
	},
}

local Assets = {
	InterFont = "rbxassetid://12187365364",
	Transform = "rbxassetid://90336395745819",
}

local function GetGui()
	local gui = Instance.new("ScreenGui")
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483647

	local parent = IsStudio
		and LocalPlayer:FindFirstChild("PlayerGui")
		or (gethui and gethui())
		or (cloneref and cloneref(SafetyChecker.GetService("CoreGui")) or SafetyChecker.GetService("CoreGui"))

	gui.Parent = parent
	return gui
end

local function Tween(Instance: Instance, Info: TweenInfo, Table: {})
	return TweenService:Create(Instance, Info, Table)
end

local function RegisterThemed(Instance: Instance, Property, Key)
	table.insert(ThemedElements, {
		instance = Instance,
		property = Property,
		key = Key
	})

	Instance[Property] = Themes[CurrentTheme][Key]
end

local function RegisterThemeCallback(Callback: () -> ())
	table.insert(ThemedCallbacks, Callback)
	Callback(CurrentTheme)
end

function SafetyChecker:Window(Settings: {})
	local WindowFunctions = {Settings = Settings}
	
	local MenuKeybind = Settings.Keybind or Enum.KeyCode.RightControl
	local Theme = Settings.Theme or "Calamari"
	
	local safety_checker = GetGui()

	local notifications = Instance.new("Frame")
	notifications.Name = "Notifications"
	notifications.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	notifications.BackgroundTransparency = 1
	notifications.BorderColor3 = Color3.fromRGB(0, 0, 0)
	notifications.BorderSizePixel = 0
	notifications.Size = UDim2.fromScale(1, 1)
	notifications.Parent = safety_checker
	notifications.ZIndex = 2

	local ui_list_layout = Instance.new("UIListLayout")
	ui_list_layout.Name = "NotificationsUIListLayout"
	ui_list_layout.Padding = UDim.new(0, 10)
	ui_list_layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	ui_list_layout.SortOrder = Enum.SortOrder.LayoutOrder
	ui_list_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	ui_list_layout.Parent = notifications

	local notifications_ui_padding = Instance.new("UIPadding")
	notifications_ui_padding.Name = "NotificationsUIPadding"
	notifications_ui_padding.PaddingBottom = UDim.new(0, 10)
	notifications_ui_padding.PaddingLeft = UDim.new(0, 10)
	notifications_ui_padding.PaddingRight = UDim.new(0, 10)
	notifications_ui_padding.PaddingTop = UDim.new(0, 10)
	notifications_ui_padding.Parent = notifications

	local base = Instance.new("Frame")
	base.Name = "Base"
	base.AnchorPoint = Vector2.new(0.5, 0.5)
	RegisterThemed(base, "BackgroundColor3", "Core")
	base.BackgroundTransparency = Settings.AcrylicBlur and 0.05 or 0
	base.BorderColor3 = Color3.fromRGB(0, 0, 0)
	base.BorderSizePixel = 0
	base.Position = UDim2.fromScale(0.5, 0.5)
	base.Size = Settings.Size or UDim2.fromOffset(500, 800)

	local base_ui_scale = Instance.new("UIScale")
	base_ui_scale.Name = "BaseUIScale"
	base_ui_scale.Parent = base

	local base_ui_corner = Instance.new("UICorner")
	base_ui_corner.Name = "BaseUICorner"
	base_ui_corner.CornerRadius = UDim.new(0, 10)
	base_ui_corner.Parent = base

	local base_ui_stroke = Instance.new("UIStroke")
	base_ui_stroke.Name = "BaseUIStroke"
	base_ui_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	base_ui_stroke.Color = Color3.fromRGB(255, 255, 255)
	base_ui_stroke.Transparency = 0.9
	base_ui_stroke.Parent = base
	
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AnchorPoint = Vector2.new(1, 0)
	content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	content.BackgroundTransparency = 1
	content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	content.BorderSizePixel = 0
	content.Position = UDim2.fromScale(1, 4.69e-08)
	content.Size = UDim2.new(1, 0, 1, 0)
	
	local topbar = Instance.new("Frame")
	topbar.Name = "Topbar"
	topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	topbar.BackgroundTransparency = 1
	topbar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	topbar.BorderSizePixel = 0
	topbar.Size = UDim2.new(1, 0, 0, 63)

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.AnchorPoint = Vector2.new(0, 1)
	divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	divider.BackgroundTransparency = 0.9
	divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromScale(0, 1)
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Parent = topbar
	
	local window_controls = Instance.new("Frame")
	window_controls.Name = "WindowControls"
	window_controls.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	window_controls.BackgroundTransparency = 1
	window_controls.BorderColor3 = Color3.fromRGB(0, 0, 0)
	window_controls.BorderSizePixel = 0
	window_controls.Size = UDim2.new(1, 0, 0, 31)

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.BackgroundColor3 = Color3.fromRGB(119, 174, 94)
	controls.BackgroundTransparency = 1
	controls.BorderColor3 = Color3.fromRGB(0, 0, 0)
	controls.BorderSizePixel = 0
	controls.Size = UDim2.fromScale(1, 1)

	local ui_list_layout = Instance.new("UIListLayout")
	ui_list_layout.Name = "UIListLayout"
	ui_list_layout.Padding = UDim.new(0, 5)
	ui_list_layout.FillDirection = Enum.FillDirection.Horizontal
	ui_list_layout.SortOrder = Enum.SortOrder.LayoutOrder
	ui_list_layout.VerticalAlignment = Enum.VerticalAlignment.Center
	ui_list_layout.Parent = controls

	local ui_padding = Instance.new("UIPadding")
	ui_padding.Name = "UIPadding"
	ui_padding.PaddingLeft = UDim.new(0, 11)
	ui_padding.Parent = controls

	local window_control_settings = {
		Sizes = { Enabled = UDim2.fromOffset(8, 8), Disabled = UDim2.fromOffset(7, 7) },
		Transparencies = { Enabled = 0, Disabled = 1 },
		StrokeTransparency = 0.9,
	}

	local stroke = Instance.new("UIStroke")
	stroke.Name = "BaseUIStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = window_control_settings.StrokeTransparency

	local exit = Instance.new("TextButton")
	exit.Name = "Exit"
	exit.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	exit.Text = ""
	exit.TextColor3 = Color3.fromRGB(0, 0, 0)
	exit.TextSize = 14
	exit.AutoButtonColor = false
	exit.BackgroundColor3 = Color3.fromRGB(250, 93, 86)
	exit.BorderColor3 = Color3.fromRGB(0, 0, 0)
	exit.BorderSizePixel = 0

	local exit_corner = Instance.new("UICorner")
	exit_corner.Name = "UICorner"
	exit_corner.CornerRadius = UDim.new(1, 0)
	exit_corner.Parent = exit

	exit.Parent = controls

	local minimize = Instance.new("TextButton")
	minimize.Name = "Minimize"
	minimize.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	minimize.Text = ""
	minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
	minimize.TextSize = 14
	minimize.AutoButtonColor = false
	minimize.BackgroundColor3 = Color3.fromRGB(252, 190, 57)
	minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
	minimize.BorderSizePixel = 0
	minimize.LayoutOrder = 1

	local minimize_corner = Instance.new("UICorner")
	minimize_corner.Name = "UICorner"
	minimize_corner.CornerRadius = UDim.new(1, 0)
	minimize_corner.Parent = minimize

	minimize.Parent = controls

	local maximize = Instance.new("TextButton")
	maximize.Name = "Maximize"
	maximize.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	maximize.Text = ""
	maximize.TextColor3 = Color3.fromRGB(0, 0, 0)
	maximize.TextSize = 14
	maximize.AutoButtonColor = false
	maximize.BackgroundColor3 = Color3.fromRGB(119, 174, 94)
	maximize.BorderColor3 = Color3.fromRGB(0, 0, 0)
	maximize.BorderSizePixel = 0
	maximize.LayoutOrder = 1
	maximize.Parent = controls
	
	local maximize_corner = Instance.new("UICorner")
	maximize_corner.Name = "UICorner"
	maximize_corner.CornerRadius = UDim.new(1, 0)
	maximize_corner.Parent = maximize

	maximize.Parent = controls

	local function ApplyState(Button: GuiButton, Enabled: boolean)
		local size = Enabled and window_control_settings.Sizes.Enabled or window_control_settings.Sizes.Disabled
		local transparency = Enabled and window_control_settings.Transparencies.Enabled or window_control_settings.Transparencies.Disabled

		Button.Size = size
		Button.BackgroundTransparency = transparency
		Button.Active = Enabled
		Button.Interactable = Enabled
		
		local children = Button:GetChildren()
		
		for i = 1, #children do
			if children[i]:IsA("UIStroke") then
				children[i].Transparency = transparency
			end
		end
		
		if not Enabled then
			stroke:Clone().Parent = Button
		end
	end

	ApplyState(maximize, false)

	local controls_list = {exit, minimize}
	for _, button in next, controls_list do
		local button_name = button.Name
		local enabled = true

		if Settings.DisabledWindowControls and table.find(Settings.DisabledWindowControls, button_name) then
			enabled = false
		end

		ApplyState(button, enabled)
	end

	controls.Parent = window_controls
	
	window_controls.Parent = topbar

	local elements = Instance.new("Frame")
	elements.Name = "Elements"
	elements.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	elements.BackgroundTransparency = 1
	elements.BorderColor3 = Color3.fromRGB(0, 0, 0)
	elements.BorderSizePixel = 0
	elements.Size = UDim2.fromScale(1, 1)

	local ui_padding2 = Instance.new("UIPadding")
	ui_padding2.Name = "UIPadding"
	ui_padding2.PaddingLeft = UDim.new(0, 20)
	ui_padding2.PaddingRight = UDim.new(0, 20)
	ui_padding2.Parent = elements

	local move_icon = Instance.new("ImageButton")
	move_icon.Name = "MoveIcon"
	move_icon.Image = Assets.Transform
	move_icon.ImageTransparency = 0.7
	RegisterThemed(move_icon, "ImageColor3", "Dragger")
	move_icon.AnchorPoint = Vector2.new(1, 0.5)
	move_icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	move_icon.BackgroundTransparency = 1
	move_icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	move_icon.BorderSizePixel = 0
	move_icon.Position = UDim2.fromScale(1, 0.5)
	move_icon.Size = UDim2.fromOffset(15, 15)
	move_icon.Parent = elements
	move_icon.Visible = not Settings.DragStyle or Settings.DragStyle == 1

	local interact = Instance.new("TextButton")
	interact.Name = "Interact"
	interact.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	interact.Text = ""
	interact.TextColor3 = Color3.fromRGB(0, 0, 0)
	interact.TextSize = 14
	interact.AnchorPoint = Vector2.new(0.5, 0.5)
	interact.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	interact.BackgroundTransparency = 1
	interact.BorderColor3 = Color3.fromRGB(0, 0, 0)
	interact.BorderSizePixel = 0
	interact.Position = UDim2.fromScale(0.5, 0.5)
	interact.Size = UDim2.fromOffset(40, 40)
	interact.Parent = move_icon
	
	local window_title = Instance.new("TextLabel")
	window_title.Name = "WindowTitle"
	window_title.FontFace = Font.new(Assets.InterFont)
	window_title.RichText = true
	window_title.Text = Settings.Title
	window_title.RichText = true
	RegisterThemed(window_title, "TextColor3", "Text")
	window_title.TextSize = 15
	window_title.TextTruncate = Enum.TextTruncate.SplitWord
	window_title.TextXAlignment = Enum.TextXAlignment.Left
	window_title.TextYAlignment = Enum.TextYAlignment.Top
	window_title.AnchorPoint = Vector2.new(0, 0.5)
	window_title.AutomaticSize = Enum.AutomaticSize.Y
	window_title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	window_title.BackgroundTransparency = 1
	window_title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	window_title.BorderSizePixel = 0
	window_title.Position = UDim2.fromScale(0.1, 0.5)
	window_title.Size = UDim2.fromScale(0.8, 0)
	window_title.Parent = elements
	
	local main_tab = Instance.new("Frame")
	main_tab.Name = "Elements"
	main_tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	main_tab.BackgroundTransparency = 1
	main_tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
	main_tab.BorderSizePixel = 0
	main_tab.Position = UDim2.fromOffset(0, 63)
	main_tab.Size = UDim2.new(1, 0, 1, -63)
	main_tab.ClipsDescendants = true
	main_tab.Parent = content

	local elements_padding = Instance.new("UIPadding")
	elements_padding.Name = "ElementsUIPadding"
	elements_padding.PaddingRight = UDim.new(0, 5)
	elements_padding.PaddingTop = UDim.new(0, 10)
	elements_padding.PaddingBottom = UDim.new(0, 10)
	elements_padding.Parent = main_tab

	local elements_scrolling = Instance.new("ScrollingFrame")
	elements_scrolling.Name = "ElementsScrolling"
	elements_scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	elements_scrolling.BottomImage = ""
	elements_scrolling.CanvasSize = UDim2.new()
	elements_scrolling.ScrollBarImageTransparency = 0.5
	elements_scrolling.ScrollBarThickness = 1
	elements_scrolling.TopImage = ""
	elements_scrolling.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	elements_scrolling.BackgroundTransparency = 1
	elements_scrolling.BorderColor3 = Color3.fromRGB(0, 0, 0)
	elements_scrolling.BorderSizePixel = 0
	elements_scrolling.Size = UDim2.fromScale(1, 1)
	elements_scrolling.ClipsDescendants = false

	local elements_scrolling_padding = Instance.new("UIPadding")
	elements_scrolling_padding.Name = "ElementsScrollingUIPadding"
	elements_scrolling_padding.PaddingBottom = UDim.new(0, 5)
	elements_scrolling_padding.PaddingLeft = UDim.new(0, 11)
	elements_scrolling_padding.PaddingRight = UDim.new(0, 3)
	elements_scrolling_padding.PaddingTop = UDim.new(0, 5)
	elements_scrolling_padding.Parent = elements_scrolling

	local elements_scrolling_layout = Instance.new("UIListLayout")
	elements_scrolling_layout.Name = "ElementsScrollingUIListLayout"
	elements_scrolling_layout.Padding = UDim.new(0, 15)
	elements_scrolling_layout.FillDirection = Enum.FillDirection.Horizontal
	elements_scrolling_layout.SortOrder = Enum.SortOrder.LayoutOrder
	elements_scrolling_layout.Parent = elements_scrolling

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.AutomaticSize = Enum.AutomaticSize.Y
	main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	main.BackgroundTransparency = 1
	main.BorderColor3 = Color3.fromRGB(0, 0, 0)
	main.BorderSizePixel = 0
	main.Position = UDim2.fromScale(0.512, 0)
	main.Size = UDim2.new(1, 0, 0, 0)

	local main_list_layout = Instance.new("UIListLayout")
	main_list_layout.Name = "MainUIListLayout"
	main_list_layout.Padding = UDim.new(0, 15)
	main_list_layout.SortOrder = Enum.SortOrder.LayoutOrder
	main_list_layout.Parent = main
	
	elements_scrolling.Parent = main_tab

	main.Parent = elements_scrolling
	
	function  WindowFunctions:Section()
		local SectionFunctions = {}
		
		local section = Instance.new("Frame")
		section.Name = "Section"
		section.AutomaticSize = Enum.AutomaticSize.Y
		section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		section.BackgroundTransparency = 0.98
		section.BorderColor3 = Color3.fromRGB(0, 0, 0)
		section.BorderSizePixel = 0
		section.Position = UDim2.fromScale(0, 6.78e-08)
		section.Size = UDim2.fromScale(1, 0)
		section.ClipsDescendants = true
		section.Parent = main

		local section_corner = Instance.new("UICorner")
		section_corner.Name = "SectionUICorner"
		section_corner.Parent = section

		local section_stroke = Instance.new("UIStroke")
		section_stroke.Name = "SectionUIStroke"
		section_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		section_stroke.Color = Color3.fromRGB(255, 255, 255)
		section_stroke.Transparency = 0.95
		section_stroke.Parent = section

		local section_list_layout = Instance.new("UIListLayout")
		section_list_layout.Name = "SectionUIListLayout"
		section_list_layout.Padding = UDim.new(0, 10)
		section_list_layout.SortOrder = Enum.SortOrder.LayoutOrder
		section_list_layout.Parent = section

		local section_padding = Instance.new("UIPadding")
		section_padding.Name = "SectionUIPadding"
		section_padding.PaddingBottom = UDim.new(0, 20)
		section_padding.PaddingLeft = UDim.new(0, 20)
		section_padding.PaddingRight = UDim.new(0, 18)
		section_padding.PaddingTop = UDim.new(0, 22)
		section_padding.Parent = section
		
		function SectionFunctions:Header(Settings: {}, Flag)
			local HeaderFunctions = {Settings = Settings}

			local header = Instance.new("Frame")
			header.Name = "Header"
			header.AutomaticSize = Enum.AutomaticSize.Y
			header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			header.BackgroundTransparency = 1
			header.BorderColor3 = Color3.fromRGB(0, 0, 0)
			header.BorderSizePixel = 0
			header.LayoutOrder = 0
			header.Size = UDim2.fromScale(1, 0)
			header.Parent = section

			local padding = Instance.new("UIPadding")
			padding.Name = "UIPadding"
			padding.PaddingBottom = UDim.new(0, 5)
			padding.Parent = header

			local header_text = Instance.new("TextLabel")
			header_text.Name = "HeaderText"
			header_text.FontFace = Font.new(
				Assets.InterFont,
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			)
			header_text.RichText = true
			header_text.Text = HeaderFunctions.Settings.Text or HeaderFunctions.Settings.Name
			RegisterThemed(header_text, "TextColor3", "Text")
			header_text.TextSize = 16
			header_text.TextTransparency = 0.3
			header_text.TextWrapped = true
			header_text.TextXAlignment = Enum.TextXAlignment.Left
			header_text.AutomaticSize = Enum.AutomaticSize.Y
			header_text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			header_text.BackgroundTransparency = 1
			header_text.BorderColor3 = Color3.fromRGB(0, 0, 0)
			header_text.BorderSizePixel = 0
			header_text.Size = UDim2.fromScale(1, 0)
			header_text.Parent = header
			
			function HeaderFunctions:Remove()
				header:Destroy()
			end

			function HeaderFunctions:UpdateName(New: string)
				header_text.Text = New
			end
			function HeaderFunctions:SetVisibility(State: boolean)
				header.Visible = State
			end

			if Flag then
				Calamari.Options[Flag] = HeaderFunctions
			end
			
			return HeaderFunctions
		end

		function SectionFunctions:Paragraph(Settings: {}, Flag)
			local ParagraphFunctions = {Settings = Settings}

			local paragraph = Instance.new("Frame")
			paragraph.Name = "Paragraph"
			paragraph.AutomaticSize = Enum.AutomaticSize.Y
			paragraph.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			paragraph.BackgroundTransparency = 1
			paragraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
			paragraph.BorderSizePixel = 0
			paragraph.Size = UDim2.new(1, 0, 0, 38)
			paragraph.Parent = section

			local paragraph_header = Instance.new("TextLabel")
			paragraph_header.Name = "ParagraphHeader"
			paragraph_header.FontFace = Font.new(
				Assets.InterFont,
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			)
			paragraph_header.RichText = true
			paragraph_header.Text = ParagraphFunctions.Settings.Header
			RegisterThemed(paragraph_header, "TextColor3", "Text")
			paragraph_header.TextSize = 15
			paragraph_header.TextTransparency = 0.4
			paragraph_header.TextWrapped = true
			paragraph_header.TextXAlignment = Enum.TextXAlignment.Left
			paragraph_header.AutomaticSize = Enum.AutomaticSize.Y
			paragraph_header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			paragraph_header.BackgroundTransparency = 1
			paragraph_header.BorderColor3 = Color3.fromRGB(0, 0, 0)
			paragraph_header.BorderSizePixel = 0
			paragraph_header.Size = UDim2.fromScale(1, 0)
			paragraph_header.Parent = paragraph

			local list_layout = Instance.new("UIListLayout")
			list_layout.Name = "UIListLayout"
			list_layout.Padding = UDim.new(0, 5)
			list_layout.SortOrder = Enum.SortOrder.LayoutOrder
			list_layout.Parent = paragraph

			local paragraph_body = Instance.new("TextLabel")
			paragraph_body.Name = "ParagraphBody"
			paragraph_body.FontFace = Font.new(Assets.InterFont)
			paragraph_body.RichText = true
			paragraph_body.Text = ParagraphFunctions.Settings.Body
			RegisterThemed(paragraph_body, "TextColor3", "Text")
			paragraph_body.TextSize = 13
			paragraph_body.TextTransparency = 0.5
			paragraph_body.TextWrapped = true
			paragraph_body.TextXAlignment = Enum.TextXAlignment.Left
			paragraph_body.AutomaticSize = Enum.AutomaticSize.Y
			paragraph_body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			paragraph_body.BackgroundTransparency = 1
			paragraph_body.BorderColor3 = Color3.fromRGB(0, 0, 0)
			paragraph_body.BorderSizePixel = 0
			paragraph_body.LayoutOrder = 1
			paragraph_body.Size = UDim2.fromScale(1, 0)
			paragraph_body.Parent = paragraph
			
			function ParagraphFunctions:Remove()
				paragraph:Destroy()
			end

			function ParagraphFunctions:UpdateHeader(New: string)
				paragraph_header.Text = New
			end
			
			function ParagraphFunctions:UpdateBody(New: string)
				paragraph_body.Text = New
			end
			
			function ParagraphFunctions:SetVisibility(State: boolean)
				paragraph.Visible = State
			end

			if Flag then
				Calamari.Options[Flag] = ParagraphFunctions
			end
			
			return ParagraphFunctions
		end

		function SectionFunctions:Divider()
			local DividerFunctions = {}

			local divider = Instance.new("Frame")
			divider.Name = "Divider"
			divider.AnchorPoint = Vector2.new(0, 1)
			divider.AutomaticSize = Enum.AutomaticSize.Y
			divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			divider.BackgroundTransparency = 1
			divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
			divider.BorderSizePixel = 0
			divider.Position = UDim2.fromScale(0, 1)
			divider.Size = UDim2.new(1, 0, 0, 1)
			divider.Parent = section

			local padding = Instance.new("UIPadding")
			padding.Name = "UIPadding"
			padding.PaddingBottom = UDim.new(0, 8)
			padding.PaddingTop = UDim.new(0, 8)
			padding.Parent = divider

			local list_layout = Instance.new("UIListLayout")
			list_layout.Name = "UIListLayout"
			list_layout.SortOrder = Enum.SortOrder.LayoutOrder
			list_layout.Parent = divider

			local line = Instance.new("Frame")
			line.Name = "Line"
			line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			line.BackgroundTransparency = 0.9
			line.BorderColor3 = Color3.fromRGB(0, 0, 0)
			line.BorderSizePixel = 0
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Parent = divider

			function DividerFunctions:Remove()
				divider:Destroy()
			end
			
			function DividerFunctions:SetVisibility(State: boolean)
				divider.Visible = State
			end

			return DividerFunctions
		end
		
		function SectionFunctions:Remove()
			section:Destroy()
		end
		
		return SectionFunctions	
	end
	
	local function ChangeIconState(State: string)
		if State == "Default" then
			Tween(move_icon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				ImageTransparency = 0.7
			}):Play()
		elseif State == "Hover" then
			Tween(move_icon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				ImageTransparency = 0.4
			}):Play()
		end
	end

	interact.MouseEnter:Connect(function()
		ChangeIconState("Hover")
	end)
	
	interact.MouseLeave:Connect(function()
		ChangeIconState("Default")
	end)

	local dragging = false
	local drag_input
	local drag_start
	local start_position

	local function Update(Input: InputObject)
		local delta = Input.Position - drag_start
		base.Position = UDim2.new(start_position.X.Scale, start_position.X.Offset + delta.X, start_position.Y.Scale, start_position.Y.Offset + delta.Y)
	end

	local function StartDrag(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			drag_start = Input.Position
			start_position = base.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end

	local function UpdateDrag(Input: InputObject)
		if dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			drag_input = Input
		end
	end

	if not Settings.DragStyle or Settings.DragStyle == 1 then
		interact.InputBegan:Connect(function(Input: InputObject)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				StartDrag(Input)
			end
		end)

		interact.InputChanged:Connect(UpdateDrag)

		UserInputService.InputChanged:Connect(function(Input: InputObject)
			if Input == drag_input and dragging then
				Update(Input)
			end
		end)

		interact.InputEnded:Connect(function(Input: InputObject)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	elseif Settings.DragStyle == 2 then
		base.InputBegan:Connect(function(Input: InputObject)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				StartDrag(Input)
			end
		end)

		base.InputChanged:Connect(UpdateDrag)

		UserInputService.InputChanged:Connect(function(Input: InputObject)
			if Input == drag_input and dragging then
				Update(Input)
			end
		end)

		base.InputEnded:Connect(function(Input: InputObject)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end
	
	local function ToggleMenu()
		local state = not WindowFunctions:GetState()
		WindowFunctions:SetState(state)
		WindowFunctions:Notify({
			Title = Settings.Title,
			Description = (state and "Maximized " or "Minimized ") .. "the menu. Use " .. tostring(MenuKeybind.Name) .. " to toggle it.",
			Lifetime = 5
		})
	end

	UserInputService.InputEnded:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then return end
		
		if Input.KeyCode == MenuKeybind then
			ToggleMenu()
		end
	end)

	minimize.MouseButton1Click:Connect(ToggleMenu)
	
	exit.MouseButton1Click:Connect(function()
		WindowFunctions:Dialog({
			Title = Settings.Title,
			Description = "Are you sure you want to exit the menu?",
			Buttons = {
				{
					Name = "Confirm",
					Callback = function()
						WindowFunctions:Unload()
					end,
				},
				{
					Name = "Cancel"
				}
			}
		})
	end)
	
	function WindowFunctions:Notify(Settings: {})
		local NotificationFunctions = {}

		local notification = Instance.new("Frame")
		notification.Name = "Notification"
		notification.AnchorPoint = Vector2.new(0.5, 0.5)
		notification.AutomaticSize = Enum.AutomaticSize.Y
		RegisterThemed(notification, "BackgroundColor3", "Core")
		notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
		notification.BorderSizePixel = 0
		notification.Position = UDim2.fromScale(0.5, 0.5)
		notification.Size = UDim2.fromOffset(Settings.SizeX or 250, 0)

		notification.Parent = notifications

		local notification_ui_stroke = Instance.new("UIStroke")
		notification_ui_stroke.Name = "NotificationUIStroke"
		notification_ui_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		notification_ui_stroke.Color = Color3.fromRGB(255, 255, 255)
		notification_ui_stroke.Transparency = 0.9
		notification_ui_stroke.Parent = notification

		local notification_ui_corner = Instance.new("UICorner")
		notification_ui_corner.Name = "NotificationUICorner"
		notification_ui_corner.CornerRadius = UDim.new(0, 10)
		notification_ui_corner.Parent = notification

		local notification_ui_scale = Instance.new("UIScale")
		notification_ui_scale.Name = "NotificationUIScale"
		notification_ui_scale.Parent = notification
		notification_ui_scale.Scale = 0

		local notification_information = Instance.new("Frame")
		notification_information.Name = "NotificationInformation"
		notification_information.AutomaticSize = Enum.AutomaticSize.Y
		notification_information.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		notification_information.BackgroundTransparency = 1
		notification_information.BorderColor3 = Color3.fromRGB(0, 0, 0)
		notification_information.BorderSizePixel = 0
		notification_information.Size = UDim2.fromScale(1, 1)

		local notification_title = Instance.new("TextLabel")
		notification_title.Name = "NotificationTitle"
		notification_title.FontFace = Font.new(
			Assets.InterFont,
			Enum.FontWeight.SemiBold,
			Enum.FontStyle.Normal
		)
		notification_title.RichText = true
		notification_title.Text = Settings.Title
		notification_title.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification_title.TextSize = 13
		notification_title.TextTransparency = 0.2
		notification_title.TextTruncate = Enum.TextTruncate.SplitWord
		notification_title.TextXAlignment = Enum.TextXAlignment.Left
		notification_title.TextYAlignment = Enum.TextYAlignment.Top
		notification_title.AutomaticSize = Enum.AutomaticSize.XY
		notification_title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		notification_title.BackgroundTransparency = 1
		notification_title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		notification_title.BorderSizePixel = 0
		notification_title.Size = UDim2.new(1, -12, 0, 0)

		local notification_title_ui_padding = Instance.new("UIPadding")
		notification_title_ui_padding.Name = "NotificationTitleUIPadding"
		notification_title_ui_padding.PaddingRight = UDim.new(0, 25)
		notification_title_ui_padding.Parent = notification_title

		notification_title.Parent = notification_information

		local notification_description = Instance.new("TextLabel")
		notification_description.Name = "NotificationDescription"
		notification_description.FontFace = Font.new(
			Assets.InterFont,
			Enum.FontWeight.Medium,
			Enum.FontStyle.Normal
		)
		notification_description.Text = Settings.Description
		notification_description.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification_description.TextSize = 11
		notification_description.TextTransparency = 0.5
		notification_description.TextWrapped = true
		notification_description.RichText = true
		notification_description.TextXAlignment = Enum.TextXAlignment.Left
		notification_description.TextYAlignment = Enum.TextYAlignment.Top
		notification_description.AutomaticSize = Enum.AutomaticSize.XY
		notification_description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		notification_description.BackgroundTransparency = 1
		notification_description.BorderColor3 = Color3.fromRGB(0, 0, 0)
		notification_description.BorderSizePixel = 0
		notification_description.Size = UDim2.new(1, -12, 0, 0)

		local notification_description_ui_padding = Instance.new("UIPadding")
		notification_description_ui_padding.Name = "NotificationDescriptionUIPadding"
		notification_description_ui_padding.PaddingRight = UDim.new(0, 25)
		notification_description_ui_padding.PaddingTop = UDim.new(0, 17)
		notification_description_ui_padding.Parent = notification_description

		notification_description.Parent = notification_information

		local notification_ui_padding = Instance.new("UIPadding")
		notification_ui_padding.Name = "NotificationUIPadding"
		notification_ui_padding.PaddingBottom = UDim.new(0, 12)
		notification_ui_padding.PaddingLeft = UDim.new(0, 10)
		notification_ui_padding.PaddingRight = UDim.new(0, 10)
		notification_ui_padding.PaddingTop = UDim.new(0, 10)
		notification_ui_padding.Parent = notification_information

		notification_information.Parent = notification

		local notification_controls = Instance.new("Frame")
		notification_controls.Name = "NotificationControls"
		notification_controls.AutomaticSize = Enum.AutomaticSize.Y
		notification_controls.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		notification_controls.BackgroundTransparency = 1
		notification_controls.BorderColor3 = Color3.fromRGB(0, 0, 0)
		notification_controls.BorderSizePixel = 0
		notification_controls.Size = UDim2.fromScale(1, 1)

		local interactable = Instance.new("TextButton")
		interactable.Name = "Interactable"
		interactable.FontFace = Font.new(Assets.InterFont)
		interactable.Text = "✓"
		interactable.TextColor3 = Color3.fromRGB(255, 255, 255)
		interactable.TextSize = 17
		interactable.TextTransparency = 0.2
		interactable.AnchorPoint = Vector2.new(1, 0.5)
		interactable.AutomaticSize = Enum.AutomaticSize.XY
		interactable.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		interactable.BackgroundTransparency = 1
		interactable.BorderColor3 = Color3.fromRGB(0, 0, 0)
		interactable.BorderSizePixel = 0
		interactable.LayoutOrder = 1
		interactable.Position = UDim2.fromScale(1, 0.5)
		interactable.Parent = notification_controls

		local controls_padding = Instance.new("UIPadding")
		controls_padding.Name = "UIPadding"
		controls_padding.PaddingBottom = UDim.new(0, 6)
		controls_padding.PaddingRight = UDim.new(0, 13)
		controls_padding.PaddingTop = UDim.new(0, 6)
		controls_padding.Parent = notification_controls

		notification_controls.Parent = notification

		local tweens = {
			In = Tween(notification_ui_scale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
				Scale = Settings.Scale or 1
			}),
			Out = Tween(notification_ui_scale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
				Scale = 0
			}),
		}

		local styles = {
			None = function() interactable:Destroy() end,
			Confirm = function() interactable.Text = "✓" end,
			Cancel = function() interactable.Text = "✗" end
		}

		local style = styles[Settings.Style] or function() interactable:Destroy() end
		
		style()

		if interactable then
			interactable.MouseButton1Click:Connect(function()
				NotificationFunctions:Cancel()
				if Settings.Callback then
					task.spawn(Settings.Callback)
				end
			end)
		end

		local AnimateNotification = task.spawn(function()
			tweens.In:Play()

			Settings.Lifetime = Settings.Lifetime or 3

			if Settings.Lifetime ~= 0 then
				task.wait(Settings.Lifetime)

				local out = tweens.Out
				out:Play()
				out.Completed:Wait()
				notification:Destroy()
			end
		end)

		function NotificationFunctions:UpdateTitle(New: string)
			notification_title.Text = New
		end

		function NotificationFunctions:UpdateDescription(New: string)
			notification_description.Text = New
		end

		function NotificationFunctions:Resize(X)
			local targ = X or 250
			notification.Size = UDim2.fromOffset(targ, 0)
		end

		function NotificationFunctions:Cancel()
			task.cancel(AnimateNotification)

			local out = tweens.Out
			out:Play()
			out.Completed:Wait()
			notification:Destroy()
		end

		return NotificationFunctions
	end

	function WindowFunctions:Dialog(Settings: {})
		local DialogFunctions = {}

		local dialog_canvas = Instance.new("CanvasGroup")
		dialog_canvas.Name = "DialogCanvas"
		dialog_canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		dialog_canvas.BackgroundTransparency = 1
		dialog_canvas.BorderColor3 = Color3.fromRGB(0, 0, 0)
		dialog_canvas.BorderSizePixel = 0
		dialog_canvas.Size = UDim2.fromScale(1, 1)
		dialog_canvas.GroupTransparency = 1
		dialog_canvas.Parent = base

		local dialog = Instance.new("Frame")
		dialog.Name = "Dialog"
		dialog.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		dialog.BackgroundTransparency = 0.5
		dialog.BorderColor3 = Color3.fromRGB(0, 0, 0)
		dialog.BorderSizePixel = 0
		dialog.Size = UDim2.fromScale(1, 1)

		local dialog_corner = Instance.new("UICorner")
		dialog_corner.Name = "BaseUICorner"
		dialog_corner.CornerRadius = UDim.new(0, 10)
		dialog_corner.Parent = dialog

		local prompt = Instance.new("Frame")
		prompt.Name = "Prompt"
		prompt.AnchorPoint = Vector2.new(0.5, 0.5)
		prompt.AutomaticSize = Enum.AutomaticSize.Y
		RegisterThemed(prompt, "BackgroundColor3", "Core")
		prompt.BorderColor3 = Color3.fromRGB(0, 0, 0)
		prompt.BorderSizePixel = 0
		prompt.Position = UDim2.fromScale(0.5, 0.5)
		prompt.Size = UDim2.fromOffset(280, 0)

		local prompt_scale = Instance.new("UIScale")
		prompt_scale.Name = "BaseUIScale"
		prompt_scale.Parent = prompt
		prompt_scale.Scale = 0.95

		local global_settings_stroke = Instance.new("UIStroke")
		global_settings_stroke.Name = "GlobalSettingsUIStroke"
		global_settings_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		global_settings_stroke.Color = Color3.fromRGB(255, 255, 255)
		global_settings_stroke.Transparency = 0.9
		global_settings_stroke.Parent = prompt

		local global_settings_corner = Instance.new("UICorner")
		global_settings_corner.Name = "GlobalSettingsUICorner"
		global_settings_corner.CornerRadius = UDim.new(0, 10)
		global_settings_corner.Parent = prompt

		local global_settings_padding = Instance.new("UIPadding")
		global_settings_padding.Name = "GlobalSettingsUIPadding"
		global_settings_padding.PaddingBottom = UDim.new(0, 20)
		global_settings_padding.PaddingLeft = UDim.new(0, 20)
		global_settings_padding.PaddingRight = UDim.new(0, 20)
		global_settings_padding.PaddingTop = UDim.new(0, 20)
		global_settings_padding.Parent = prompt

		local paragraph = Instance.new("Frame")
		paragraph.Name = "Paragraph"
		paragraph.AutomaticSize = Enum.AutomaticSize.Y
		paragraph.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		paragraph.BackgroundTransparency = 1
		paragraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
		paragraph.BorderSizePixel = 0
		paragraph.Size = UDim2.new(1, 0, 0, 38)

		local paragraph_header = Instance.new("TextLabel")
		paragraph_header.Name = "ParagraphHeader"
		paragraph_header.FontFace = Font.new(
			Assets.InterFont,
			Enum.FontWeight.Medium,
			Enum.FontStyle.Normal
		)
		paragraph_header.RichText = true
		paragraph_header.Text = Settings.Title
		paragraph_header.TextColor3 = Color3.fromRGB(255, 255, 255)
		paragraph_header.TextSize = 18
		paragraph_header.TextTransparency = 0.4
		paragraph_header.TextWrapped = true
		paragraph_header.AutomaticSize = Enum.AutomaticSize.Y
		paragraph_header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		paragraph_header.BackgroundTransparency = 1
		paragraph_header.BorderColor3 = Color3.fromRGB(0, 0, 0)
		paragraph_header.BorderSizePixel = 0
		paragraph_header.Size = UDim2.fromScale(1, 0)
		paragraph_header.Parent = paragraph

		local list_layout = Instance.new("UIListLayout")
		list_layout.Name = "UIListLayout"
		list_layout.Padding = UDim.new(0, 15)
		list_layout.SortOrder = Enum.SortOrder.LayoutOrder
		list_layout.Parent = paragraph

		local paragraph_body = Instance.new("TextLabel")
		paragraph_body.Name = "ParagraphBody"
		paragraph_body.FontFace = Font.new(Assets.InterFont)
		paragraph_body.RichText = true
		paragraph_body.Text = Settings.Description
		paragraph_body.TextColor3 = Color3.fromRGB(255, 255, 255)
		paragraph_body.TextSize = 14
		paragraph_body.TextTransparency = 0.5
		paragraph_body.TextWrapped = true
		paragraph_body.AutomaticSize = Enum.AutomaticSize.Y
		paragraph_body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		paragraph_body.BackgroundTransparency = 1
		paragraph_body.BorderColor3 = Color3.fromRGB(0, 0, 0)
		paragraph_body.BorderSizePixel = 0
		paragraph_body.LayoutOrder = 1
		paragraph_body.Size = UDim2.fromScale(1, 0)
		paragraph_body.Parent = paragraph

		paragraph.Parent = prompt

		local interactions = Instance.new("Frame")
		interactions.Name = "Interactions"
		interactions.AutomaticSize = Enum.AutomaticSize.Y
		interactions.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		interactions.BackgroundTransparency = 1
		interactions.BorderColor3 = Color3.fromRGB(0, 0, 0)
		interactions.BorderSizePixel = 0
		interactions.LayoutOrder = 1
		interactions.Size = UDim2.fromScale(1, 0)

		local list_layout1 = Instance.new("UIListLayout")
		list_layout1.Name = "UIListLayout"
		list_layout1.Padding = UDim.new(0, 10)
		list_layout1.SortOrder = Enum.SortOrder.LayoutOrder
		list_layout1.Parent = interactions

		local controls_padding = Instance.new("UIPadding")
		controls_padding.Name = "UIPadding"
		controls_padding.PaddingTop = UDim.new(0, 20)
		controls_padding.Parent = interactions

		interactions.Parent = prompt

		local list_layout2 = Instance.new("UIListLayout")
		list_layout2.Name = "UIListLayout"
		list_layout2.SortOrder = Enum.SortOrder.LayoutOrder
		list_layout2.Parent = prompt

		prompt.Parent = dialog

		dialog.Parent = dialog_canvas

		local canvas_in = Tween(dialog_canvas, TweenInfo.new(0.1, Enum.EasingStyle.Sine), { GroupTransparency = 0 })
		local canvas_out = Tween(dialog_canvas, TweenInfo.new(0.1, Enum.EasingStyle.Sine), { GroupTransparency = 1 })

		local scale_in = Tween(prompt_scale, TweenInfo.new(0.1, Enum.EasingStyle.Sine), { Scale = 1 })
		local scale_out = Tween(prompt_scale, TweenInfo.new(0.1, Enum.EasingStyle.Sine), { Scale = 0.95 })

		local function DialogIn()
			canvas_in:Play()
			scale_in:Play()
			canvas_in.Completed:Wait()
			dialog.Parent = base
		end

		local function DialogOut()
			if not dialog.Parent then return end
			
			dialog.Parent = dialog_canvas
			canvas_out:Play()
			scale_out:Play()
			canvas_out.Completed:Wait()
			dialog_canvas:Destroy()
		end

		for _, v in next, Settings.Buttons do
			local button = Instance.new("TextButton")
			button.Name = "Button"
			button.FontFace = Font.new(Assets.InterFont)
			button.Text = v.Name
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.TextSize = 15
			button.TextTransparency = 0.5
			button.TextTruncate = Enum.TextTruncate.AtEnd
			button.AutoButtonColor = false
			button.AutomaticSize = Enum.AutomaticSize.Y
			RegisterThemed(button, "BackgroundColor3", "Dialogue")
			button.BorderColor3 = Color3.fromRGB(0, 0, 0)
			button.BorderSizePixel = 0
			button.Size = UDim2.fromScale(1, 0)

			local controls_padding1 = Instance.new("UIPadding")
			controls_padding1.Name = "UIPadding"
			controls_padding1.PaddingBottom = UDim.new(0, 9)
			controls_padding1.PaddingLeft = UDim.new(0, 10)
			controls_padding1.PaddingRight = UDim.new(0, 10)
			controls_padding1.PaddingTop = UDim.new(0, 9)
			controls_padding1.Parent = button

			local base_corner1 = Instance.new("UICorner")
			base_corner1.Name = "BaseUICorner"
			base_corner1.CornerRadius = UDim.new(0, 10)
			base_corner1.Parent = button

			button.Parent = interactions

			local TweenSettings = {
				DefaultTransparency = 0,
				DefaultTransparency2 = 0.5,
				HoverTransparency = 0.3,
				HoverTransparency2 = 0.6,

				EasingStyle = Enum.EasingStyle.Sine
			}

			local function ChangeState(State: string)
				if State == "Idle" then
					Tween(button, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
						BackgroundTransparency = TweenSettings.DefaultTransparency,
						TextTransparency = TweenSettings.DefaultTransparency2
					}):Play()
				elseif State == "Hover" then
					Tween(button, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
						BackgroundTransparency = TweenSettings.HoverTransparency,
						TextTransparency = TweenSettings.HoverTransparency2
					}):Play()
				end
			end

			button.MouseButton1Click:Connect(function()
				if dialog_canvas.GroupTransparency ~= 0 then return end
				
				if v.Callback then
					v.Callback()
				end

				DialogOut()
			end)

			button.MouseEnter:Connect(function()
				ChangeState("Hover")
			end)
			button.MouseLeave:Connect(function()
				ChangeState("Idle")
			end)
		end

		DialogIn()

		function DialogFunctions:UpdateTitle(New: string)
			paragraph_header.Text = New
		end
		function DialogFunctions:UpdateDescription(New: string)
			paragraph_body.Text = New
		end

		function DialogFunctions:Cancel()
			DialogOut()
		end

		return DialogFunctions
	end
	
	function WindowFunctions:SetState(State: boolean)
		WindowState = State
		base.Visible = State
	end

	function WindowFunctions:GetState()
		return WindowState
	end

	function WindowFunctions:Unload()
		if UnloadCallback then
			UnloadCallback()  
		end

		safety_checker:Destroy()
		Unloaded = true
	end

	function WindowFunctions.OnUnloaded(Callback: () -> ())
		UnloadCallback = Callback
	end
	
	function WindowFunctions:SetTheme(ThemeName: string)
		if not Themes[ThemeName] then
			return false, "Theme '" .. ThemeName .. "' does not exist."
		end

		CurrentTheme = ThemeName

		for _, entry in next, ThemedElements do
			if entry.instance and entry.instance.Parent then
				entry.instance[entry.property] = Themes[ThemeName][entry.key]
			end
		end

		return true
	end
	
	WindowFunctions:SetTheme(Theme)
	
	elements.Parent = topbar
	topbar.Parent = content
	content.Parent = base
	base.Parent = safety_checker
	
	safety_checker.Enabled = true
	
	WindowState = true
	
	return WindowFunctions
end

return SafetyChecker
