-- [[ REDZ HUB - Steal an Egg ]] --
-- Author: Redz
-- Theme: Modern Dark-Blue & White
-- Features: Key System (Firebase RTDB), Main, Tools, Optimizer

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Cleanup GUI Lama jika ada
if CoreGui:FindFirstChild("RedzHubGui") then
    CoreGui.RedzHubGui:Destroy()
end

-- File Storage Key
local KEY_FILE = "RedzHub_Key.txt"

-- State Management Configuration
local Config = {
    AutoSteal = false,
    AutoPlace = false,
    AutoHatch = false,
    AutoSell = false,
    AntiGuard = false,
    AntiTrap = false,
    AntiRagdoll = false,
    SelectedLocations = {},
    SelectedRarities = {},
    SelectedSellRarities = {}
}

-- List Data
local Locations = {
    "Lake", "Gurun", "Jungle", "Snow", "Volcano", 
    "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom", 
    "Titan Temple", "Angel & Demons"
}

local Rarities = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", 
    "Mythic", "Cosmic", "Secret", "Eternal", "Divine"
}

-- ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RedzHubGui"
ScreenGui.ResetOnSpawn = false
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--------------------------------------------------------------------------------
-- 0. FIREBASE KEY SYSTEM (REST API)
--------------------------------------------------------------------------------
local function verifyKeyInFirebase(userKey)
    if not userKey or #userKey == 0 then
        return false, "Key tidak boleh kosong!"
    end

    local key = string.gsub(userKey, "%s+", "") -- Clean whitespace
    local endpoints = {
        "https://limone-24cc5-default-rtdb.firebaseio.com/key_redzhub/" .. key .. ".json",
        "https://limone-24cc5.firebaseio.com/key_redzhub/" .. key .. ".json"
    }

    local responseData = nil
    for _, url in ipairs(endpoints) do
        local success, res = pcall(function()
            return game:HttpGet(url)
        end)
        if success and res and res ~= "null" and res ~= "" then
            local decSuccess, decoded = pcall(function() return HttpService:JSONDecode(res) end)
            if decSuccess and type(decoded) == "table" then
                responseData = decoded
                break
            end
        end
    end

    if not responseData then
        return false, "Key tidak ditemukan!"
    end

    -- Validasi Expired
    local now = os.time()
    local expTime = tonumber(responseData.expired) or 0
    
    if expTime > 0 and now > expTime then
        return false, "Key sudah kadaluarsa (Expired)!"
    end

    return true, "Key Valid!", responseData
end

local function getSavedKey()
    if readfile and isfile and isfile(KEY_FILE) then
        local success, content = pcall(readfile, KEY_FILE)
        if success then return content end
    end
    return nil
end

local function saveKeyLocally(key)
    if writefile then
        pcall(writefile, KEY_FILE, key)
    end
end

--------------------------------------------------------------------------------
-- 1. KEY SYSTEM UI
--------------------------------------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Size = UDim2.new(0, 360, 0, 220)
KeyFrame.Position = UDim2.new(0.5, -180, 0.5, -110)
KeyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true
KeyFrame.Visible = false
KeyFrame.Parent = ScreenGui

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 10)
KeyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Color = Color3.fromRGB(0, 162, 255)
KeyStroke.Thickness = 1.5
KeyStroke.Parent = KeyFrame

local KeyTitleBar = Instance.new("TextLabel")
KeyTitleBar.Size = UDim2.new(1, 0, 0, 40)
KeyTitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
KeyTitleBar.Text = "⚡ REDZ HUB <font color=\"#00A2FF\">| Key System</font>"
KeyTitleBar.RichText = true
KeyTitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyTitleBar.TextSize = 14
KeyTitleBar.Font = Enum.Font.GothamBold
KeyTitleBar.Parent = KeyFrame

local KeyTitleCorner = Instance.new("UICorner")
KeyTitleCorner.CornerRadius = UDim.new(0, 10)
KeyTitleCorner.Parent = KeyTitleBar

local KeyInputBox = Instance.new("TextBox")
KeyInputBox.Size = UDim2.new(1, -40, 0, 38)
KeyInputBox.Position = UDim2.new(0, 20, 0, 60)
KeyInputBox.BackgroundColor3 = Color3.fromRGB(26, 26, 35)
KeyInputBox.PlaceholderText = "Masukkan 8 Digit Key (Contoh: FREE1DAY)"
KeyInputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
KeyInputBox.Text = ""
KeyInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInputBox.TextSize = 12
KeyInputBox.Font = Enum.Font.GothamMedium
KeyInputBox.Parent = KeyFrame

local KeyInputCorner = Instance.new("UICorner")
KeyInputCorner.CornerRadius = UDim.new(0, 6)
KeyInputCorner.Parent = KeyInputBox

local KeyStatusLabel = Instance.new("TextLabel")
KeyStatusLabel.Size = UDim2.new(1, -40, 0, 20)
KeyStatusLabel.Position = UDim2.new(0, 20, 0, 105)
KeyStatusLabel.BackgroundTransparency = 1
KeyStatusLabel.Text = "Silakan masukkan key Anda."
KeyStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
KeyStatusLabel.TextSize = 11
KeyStatusLabel.Font = Enum.Font.Gotham
KeyStatusLabel.Parent = KeyFrame

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Size = UDim2.new(1, -40, 0, 36)
SubmitKeyBtn.Position = UDim2.new(0, 20, 0, 135)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
SubmitKeyBtn.Text = "VERIFIKASI KEY"
SubmitKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitKeyBtn.TextSize = 13
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.Parent = KeyFrame

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.CornerRadius = UDim.new(0, 6)
SubmitCorner.Parent = SubmitKeyBtn

--------------------------------------------------------------------------------
-- 2. MAIN FRAME UI
--------------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 380)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 162, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Header Title
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 2)
HeaderLine.Position = UDim2.new(0, 0, 1, -2)
HeaderLine.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -90, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ REDZ HUB <font color=\"#00A2FF\">| Steal an Egg</font>"
TitleText.RichText = true
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 15
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Minimize & Close
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -68, 0, 6)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

--------------------------------------------------------------------------------
-- 3. SIDEBAR & TAB SYSTEM (MAIN, TOOLS, OPTIMIZER)
--------------------------------------------------------------------------------
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 8)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 12)
SidebarPadding.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -50)
ContentContainer.Position = UDim2.new(0, 135, 0, 45)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Pages = {}

local function createTab(name, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 110, 0, 35)
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 13
    TabBtn.LayoutOrder = layoutOrder
    TabBtn.Parent = Sidebar

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(0, 162, 255)
    Page.Visible = false
    Page.Parent = ContentContainer

    local PageList = Instance.new("UIListLayout")
    PageList.Padding = UDim.new(0, 10)
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Parent = Page

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingRight = UDim.new(0, 8)
    PagePadding.Parent = Page

    Pages[name] = {Btn = TabBtn, Page = Page}

    TabBtn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Pages) do
            tab.Page.Visible = false
            tab.Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            tab.Btn.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return Page
end

local MainPage = createTab("MAIN", 1)
local ToolsPage = createTab("TOOLS", 2)
local OptimizerPage = createTab("OPTIMIZER", 3)

Pages["MAIN"].Page.Visible = true
Pages["MAIN"].Btn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
Pages["MAIN"].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)

--------------------------------------------------------------------------------
-- 4. HELPER UI COMPONENTS
--------------------------------------------------------------------------------
local function createSection(parent, title)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 22)
    Label.BackgroundTransparency = 1
    Label.Text = "<b>" .. title:upper() .. "</b>"
    Label.RichText = true
    Label.TextColor3 = Color3.fromRGB(0, 162, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent
end

local function createToggle(parent, text, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 36)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    ToggleFrame.Parent = parent

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -50, 1, 0)
    TextLabel.Position = UDim2.new(0, 10, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = text
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextSize = 13
    TextLabel.Font = Enum.Font.GothamMedium
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Parent = ToggleFrame

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 36, 0, 20)
    Btn.Position = UDim2.new(1, -44, 0.5, -10)
    Btn.BackgroundColor3 = default and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(45, 45, 55)
    Btn.Text = ""
    Btn.Parent = ToggleFrame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(1, 0)
    BtnCorner.Parent = Btn

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Dot.Parent = Btn

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = Dot

    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.BackgroundColor3 = state and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(45, 45, 55)
        Dot.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        callback(state)
    end)
end

local function createMultiSelectGrid(parent, list, targetTable)
    local GridFrame = Instance.new("Frame")
    GridFrame.Size = UDim2.new(1, 0, 0, 0)
    GridFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    GridFrame.Parent = parent

    local GridCorner = Instance.new("UICorner")
    GridCorner.CornerRadius = UDim.new(0, 6)
    GridCorner.Parent = GridFrame

    local UIGrid = Instance.new("UIGridLayout")
    UIGrid.CellSize = UDim2.new(0, 120, 0, 26)
    UIGrid.CellPadding = UDim2.new(0, 6, 0, 6)
    UIGrid.SortOrder = Enum.SortOrder.LayoutOrder
    UIGrid.Parent = GridFrame

    local GridPadding = Instance.new("UIPadding")
    GridPadding.PaddingTop = UDim.new(0, 6)
    GridPadding.PaddingLeft = UDim.new(0, 6)
    GridPadding.PaddingRight = UDim.new(0, 6)
    GridPadding.PaddingBottom = UDim.new(0, 6)
    GridPadding.Parent = GridFrame

    for _, item in ipairs(list) do
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Text = item
        ItemBtn.Font = Enum.Font.GothamMedium
        ItemBtn.TextSize = 11
        ItemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        ItemBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        ItemBtn.Parent = GridFrame

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 4)
        ItemCorner.Parent = ItemBtn

        ItemBtn.MouseButton1Click:Connect(function()
            if targetTable[item] then
                targetTable[item] = nil
                ItemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                ItemBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
            else
                targetTable[item] = true
                ItemBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
                ItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end)
    end

    local rows = math.ceil(#list / 3)
    GridFrame.Size = UDim2.new(1, 0, 0, (rows * 32) + 8)
end

--------------------------------------------------------------------------------
-- 5. CONTENT TAB MAIN
--------------------------------------------------------------------------------
createSection(MainPage, "Auto Automation")
createToggle(MainPage, "Auto Steal Egg", false, function(v) Config.AutoSteal = v end)
createToggle(MainPage, "Auto Place Egg", false, function(v) Config.AutoPlace = v end)
createToggle(MainPage, "Auto Hatch Egg", false, function(v) Config.AutoHatch = v end)

createSection(MainPage, "Egg Filter - Location")
createMultiSelectGrid(MainPage, Locations, Config.SelectedLocations)

createSection(MainPage, "Egg Filter - Rarity")
createMultiSelectGrid(MainPage, Rarities, Config.SelectedRarities)

createSection(MainPage, "Auto Sell")
createToggle(MainPage, "Auto Sell Eggs/Pets", false, function(v) Config.AutoSell = v end)
createSection(MainPage, "Auto Sell - Rarity Target")
createMultiSelectGrid(MainPage, Rarities, Config.SelectedSellRarities)

--------------------------------------------------------------------------------
-- 6. CONTENT TAB TOOLS (BARU)
--------------------------------------------------------------------------------
createSection(ToolsPage, "Protection & Immunity")

createToggle(ToolsPage, "Anti Hit Guard", false, function(v) 
    Config.AntiGuard = v 
end)

createToggle(ToolsPage, "Anti Trap", false, function(v) 
    Config.AntiTrap = v 
end)

createToggle(ToolsPage, "Anti Ragdoll", false, function(v) 
    Config.AntiRagdoll = v 
end)

--------------------------------------------------------------------------------
-- 7. CONTENT TAB OPTIMIZER
--------------------------------------------------------------------------------
createSection(OptimizerPage, "Graphics & Performance Options")

createToggle(OptimizerPage, "Matikan Bayangan (Shadows)", false, function(val)
    Lighting.GlobalShadows = not val
end)

createToggle(OptimizerPage, "Low Textures / Smooth Material", false, function(val)
    if val then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
    end
end)

createToggle(OptimizerPage, "Hapus Partikel & Fog", false, function(val)
    if val then
        Lighting.FogEnd = 9e9
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end
end)

createToggle(OptimizerPage, "Fullbright / Terang", false, function(val)
    if val then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = 1
    end
end)

local AuthorLabel = Instance.new("TextLabel")
AuthorLabel.Size = UDim2.new(1, 0, 0, 25)
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Text = "RedzHub | Developed by Redz"
AuthorLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
AuthorLabel.TextSize = 12
AuthorLabel.Font = Enum.Font.GothamItalic
AuthorLabel.Parent = OptimizerPage

--------------------------------------------------------------------------------
-- 8. MINIMIZE LOGO "RH" & CLOSE MODAL
--------------------------------------------------------------------------------
local MinimizedFrame = Instance.new("Frame")
MinimizedFrame.Name = "MinimizedFrame"
MinimizedFrame.Size = UDim2.new(0, 55, 0, 55)
MinimizedFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MinimizedFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MinimizedFrame.Visible = false
MinimizedFrame.Active = true
MinimizedFrame.Draggable = true
MinimizedFrame.Parent = ScreenGui

local MinimizedCorner = Instance.new("UICorner")
MinimizedCorner.CornerRadius = UDim.new(0, 12)
MinimizedCorner.Parent = MinimizedFrame

local MinimizedStroke = Instance.new("UIStroke")
MinimizedStroke.Color = Color3.fromRGB(0, 162, 255)
MinimizedStroke.Thickness = 2
MinimizedStroke.Parent = MinimizedFrame

local LogoBtn = Instance.new("TextButton")
LogoBtn.Size = UDim2.new(1, 0, 1, 0)
LogoBtn.BackgroundTransparency = 1
LogoBtn.Text = "RH"
LogoBtn.TextColor3 = Color3.fromRGB(0, 162, 255)
LogoBtn.TextSize = 22
LogoBtn.Font = Enum.Font.GothamBold
LogoBtn.Parent = MinimizedFrame

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizedFrame.Visible = true
end)

LogoBtn.MouseButton1Click:Connect(function()
    MinimizedFrame.Visible = false
    MainFrame.Visible = true
end)

-- Confirm Close Modal
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Name = "ConfirmFrame"
ConfirmFrame.Size = UDim2.new(1, 0, 1, 0)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmFrame.BackgroundTransparency = 0.5
ConfirmFrame.Visible = false
ConfirmFrame.ZIndex = 10
ConfirmFrame.Parent = MainFrame

local ConfirmModal = Instance.new("Frame")
ConfirmModal.Size = UDim2.new(0, 280, 0, 140)
ConfirmModal.Position = UDim2.new(0.5, -140, 0.5, -70)
ConfirmModal.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
ConfirmModal.Parent = ConfirmFrame

local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 10)
ConfirmCorner.Parent = ConfirmModal

local ConfirmStroke = Instance.new("UIStroke")
ConfirmStroke.Color = Color3.fromRGB(0, 162, 255)
ConfirmStroke.Thickness = 1.5
ConfirmStroke.Parent = ConfirmModal

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, 0, 0, 50)
ConfirmTitle.Position = UDim2.new(0, 0, 0, 10)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "You are ready to close"
ConfirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmTitle.TextSize = 15
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.Parent = ConfirmModal

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.new(0, 100, 0, 35)
YesBtn.Position = UDim2.new(0, 30, 1, -48)
YesBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
YesBtn.Text = "Yes"
YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
YesBtn.TextSize = 13
YesBtn.Font = Enum.Font.GothamBold
YesBtn.Parent = ConfirmModal

local YesCorner = Instance.new("UICorner")
YesCorner.CornerRadius = UDim.new(0, 6)
YesCorner.Parent = YesBtn

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.new(0, 100, 0, 35)
NoBtn.Position = UDim2.new(1, -130, 1, -48)
NoBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
NoBtn.Text = "No"
NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoBtn.TextSize = 13
NoBtn.Font = Enum.Font.GothamBold
NoBtn.Parent = ConfirmModal

local NoCorner = Instance.new("UICorner")
NoCorner.CornerRadius = UDim.new(0, 6)
NoCorner.Parent = NoBtn

CloseBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = true end)
NoBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = false end)
YesBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

--------------------------------------------------------------------------------
-- 9. LOGIKA PEMERIKSAAN KEY AUTOMATIS SAAT EXECUTE
--------------------------------------------------------------------------------
local function unlockMainUI()
    KeyFrame.Visible = false
    MainFrame.Visible = true
end

SubmitKeyBtn.MouseButton1Click:Connect(function()
    local enteredKey = KeyInputBox.Text
    KeyStatusLabel.Text = "Memeriksa key di database..."
    KeyStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    task.spawn(function()
        local isValid, msg, data = verifyKeyInFirebase(enteredKey)
        if isValid then
            KeyStatusLabel.Text = "Key Berhasil! Membuka RedzHub..."
            KeyStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
            saveKeyLocally(enteredKey)
            task.wait(1)
            unlockMainUI()
        else
            KeyStatusLabel.Text = msg
            KeyStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end)

-- Cek apakah ada key lokal yang sudah tersimpan
local savedKey = getSavedKey()
if savedKey then
    task.spawn(function()
        local isValid = verifyKeyInFirebase(savedKey)
        if isValid then
            unlockMainUI()
        else
            KeyFrame.Visible = true
        end
    end)
else
    KeyFrame.Visible = true
end

--------------------------------------------------------------------------------
-- 10. GAME LOOPS & TOOLS SYSTEM LOGIC
--------------------------------------------------------------------------------
-- Anti Ragdoll Loop
RunService.Stepped:Connect(function()
    if Config.AntiRagdoll and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        for _, item in pairs(LocalPlayer.Character:GetDescendants()) do
            if item:IsA("Script") or item:IsA("LocalScript") then
                if string.find(item.Name:lower(), "ragdoll") or string.find(item.Name:lower(), "knock") then
                    item.Disabled = true
                end
            end
        end
    end
end)

-- Automation & Guard/Trap Loop
task.spawn(function()
    while task.wait(0.3) do
        -- Anti Hit Guard
        if Config.AntiGuard then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:lower():find("guard") or obj.Parent.Name:lower():find("guard") then
                        if obj:IsA("TouchTransporter") or obj:IsA("TouchInterest") then
                            obj:Destroy()
                        elseif obj:IsA("BasePart") then
                            obj.CanTouch = false
                        end
                    end
                end
            end)
        end

        -- Anti Trap
        if Config.AntiTrap then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:lower():find("trap") or obj.Parent.Name:lower():find("trap") or obj.Name:lower():find("spike") then
                        if obj:IsA("TouchInterest") then
                            obj:Destroy()
                        elseif obj:IsA("BasePart") then
                            obj.CanTouch = false
                        end
                    end
                end
            end)
        end

        -- Auto Steal Loop
        if Config.AutoSteal then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local eggName = obj.Parent and obj.Parent.Name or ""
                        local matchLocation = next(Config.SelectedLocations) == nil
                        local matchRarity = next(Config.SelectedRarities) == nil

                        for loc, _ in pairs(Config.SelectedLocations) do
                            if string.find(eggName:lower(), loc:lower()) or string.find(obj.Parent.Parent.Name:lower(), loc:lower()) then
                                matchLocation = true
                            end
                        end

                        for rar, _ in pairs(Config.SelectedRarities) do
                            if string.find(eggName:lower(), rar:lower()) then
                                matchRarity = true
                            end
                        end

                        if matchLocation and matchRarity then
                            fireproximityprompt(obj)
                        end
                    end
                end
            end)
        end

        -- Auto Place Loop
        if Config.AutoPlace then
            pcall(function()
                local placeRemote = ReplicatedStorage:FindFirstChild("PlaceEgg", true) or ReplicatedStorage:FindFirstChild("Place", true)
                if placeRemote and placeRemote:IsA("RemoteEvent") then
                    placeRemote:FireServer()
                end
            end)
        end

        -- Auto Hatch Loop
        if Config.AutoHatch then
            pcall(function()
                local hatchRemote = ReplicatedStorage:FindFirstChild("HatchEgg", true) or ReplicatedStorage:FindFirstChild("Hatch", true)
                if hatchRemote and hatchRemote:IsA("RemoteEvent") then
                    hatchRemote:FireServer()
                end
            end)
        end

        -- Auto Sell Loop
        if Config.AutoSell then
            pcall(function()
                local sellRemote = ReplicatedStorage:FindFirstChild("SellEgg", true) or ReplicatedStorage:FindFirstChild("Sell", true)
                if sellRemote and sellRemote:IsA("RemoteEvent") then
                    for rarity, _ in pairs(Config.SelectedSellRarities) do
                        sellRemote:FireServer(rarity)
                    end
                end
            end)
        end
    end
end)
