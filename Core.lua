GugiInstance = LibStub("AceAddon-3.0"):NewAddon("GugiInstance", "AceConsole-3.0", "AceEvent-3.0")
GugiInstance:RegisterChatCommand("gugiinstance", "Command")
GugiInstance:RegisterChatCommand("gugii", "Command")
GugiInstance:RegisterChatCommand("gi", "Command")
GugiInstanceGui = LibStub("AceGUI-3.0")

-- GLOBALS

local locale = GetLocale()

INSTANCES = {}

if locale == "enUS" or locale == "enGB" then
    INSTANCES[1] = "Assault on Violet Hold"
    INSTANCES[2] = "Black Rook Hold"
    INSTANCES[3] = "Court of Stars"
    INSTANCES[4] = "Darkheart Thicket"
    INSTANCES[5] = "Eye of Azshara"
    INSTANCES[6] = "Halls of Valor"
    INSTANCES[7] = "Maw of Souls"
    INSTANCES[8] = "Neltharion's Lair"
    INSTANCES[9] = "The Arcway"
    INSTANCES[10] = "Vault of the Wardens"
    SYNCHRONIZE = "Synchronize"
    SUMMARY = "Summary"
    FREE = "FREE"
    LOCKED = "LOCKED"
elseif locale == "deDE" then
    INSTANCES[1] = "Sturm auf die Violette Festung"
    INSTANCES[2] = "Die Rabenwehr"
    INSTANCES[3] = "Der Hof der Sterne"
    INSTANCES[4] = "Das Finsterherzdickicht"
    INSTANCES[5] = "Das Auge Azsharas"
    INSTANCES[6] = "Die Hallen der Tapferkeit"
    INSTANCES[7] = "Der Seelenschlund"
    INSTANCES[8] = "Neltharions Hort"
    INSTANCES[9] = "Der Arkus"
    INSTANCES[10] = "Das Verlies der Wächterinnen"
    SYNCHRONIZE = "Synchronisationsprozess starten"
    SUMMARY = "Zusammenfassung"
    FREE = "FREI"
    LOCKED = "GESPERRT"
else
    GugiInstance:Print("[ERROR] Addon is not translated for your locale.")
end

MYTHIC5 = 23

CHANNEL_PREFIX = "GugiInstance"
CHANNEL_REQUEST = CHANNEL_PREFIX .. "R"
CHANNEL_ANSWER = CHANNEL_PREFIX .. "A"
EMPTY_PLAYER = "-\n\n-\n\n-\n\n-\n\n-\n\n-\n\n-\n\n-\n\n-\n\n-\n\n-"

-- END GLOBALS

function GugiInstance:OnInitialize()
    self.players = {}
    local success = RegisterAddonMessagePrefix(CHANNEL_REQUEST)
    success = success and RegisterAddonMessagePrefix(CHANNEL_ANSWER)
    if not success then
        self:Print("[ERROR] Could not register addon channels!")
    else
        self:RegisterEvent("CHAT_MSG_ADDON", "OnAddonMessage")
    end
end

function GugiInstance:OnAddonMessage(event, prefix, message, sender)
    if prefix == CHANNEL_ANSWER then
        local info = {}
        for word in string.gmatch(message, '([^#]+)') do
            info[#info + 1] = word
        end
        self:AddInfo(info)
        self:UpdateInfo()
    elseif prefix == CHANNEL_REQUEST then
        self:SendInfo()
    end
end

function GugiInstance:ShowFrame()
    if self.frame then
        return
    end
    
    self:AddInfo(self:GetOwnInfo())
    
    self.frame = GugiInstanceGui:Create("Frame")
    self.frame:Show()
    self.frame:SetTitle("Gugi Instance Checker")
    self.frame:SetCallback("OnClose",
        function(widget)
            GugiInstanceGui:Release(widget)
            self.frame = nil
        end
    )
    self.frame:SetLayout("Flow")
    
    local buttonGroup = GugiInstanceGui:Create("SimpleGroup")
    buttonGroup:SetFullWidth(true)
    self.frame:AddChild(buttonGroup)
    
    local syncButton = GugiInstanceGui:Create("Button")
    syncButton:SetText(SYNCHRONIZE)
    syncButton:SetCallback("OnClick",
        function()
            GugiInstance:SendSyncRequest()
        end
    )
    
    buttonGroup:AddChild(syncButton)
    
    local header = GugiInstanceGui:Create("InlineGroup")
    header:SetFullHeight(true)
    header:SetWidth(200)
    header:SetLayout("Flow")
    
    local label = GugiInstanceGui:Create("Label")
    header:AddChild(label)
    
    local labelText = ""
    
    for i = 1, #INSTANCES do
        labelText = labelText .. "\n\n|cffffcc00" .. INSTANCES[i] .. "|r"
    end
    
    label:SetText(labelText)
    label:SetFullWidth(true)
    label:SetFullHeight(true)
    
    
    self.playerFrames = {}
    self.playerLabels = {}
    
    self.frame:AddChild(header)
    
    for i = 1, 6 do
        local container = GugiInstanceGui:Create("InlineGroup")
        container:SetHeight(300)
        container:SetWidth(160)
        container:SetLayout("Flow")
        
        local label = GugiInstanceGui:Create("Label")
        label:SetText(EMPTY_PLAYER)
        label:SetFullWidth(true)
        label:SetFullHeight(true)
        container:AddChild(label)
        
        self.frame:AddChild(container)
        
        self.playerFrames[#self.playerFrames + 1] = container
        self.playerLabels[#self.playerLabels + 1] = label
    end
    
    
    
    self:UpdateInfo()
    
    self.frame:SetCallback("OnShow",
        function()
            self.frame:DoLayout()
            self:UpdateInfo()
            self.frame:DoLayout()
            self.frame:Show()
        end
    )
    self.frame:SetHeight(350)
    self.frame:DoLayout()
    
    GugiInstance:SendSyncRequest()
end

function GugiInstance:UpdateInfo()
    if not self.frame then  
        return
    end

    local count = 0
    for _ in pairs(self.players) do
        count = count + 1
    end
    
    local index = 1
    local frees = {}
    
    for playerName, info in pairs(self.players) do
        local frame = self.playerFrames[index]
        local text = playerName
        for j = 1, #INSTANCES do
            if info[j] then
                text = text .. "\n\n|cffff0000"..LOCKED.."|r"
            else
                text = text .. "\n\n|cff00ff00"..FREE.."|r"
                frees[j] = (frees[j] or 0) + 1
            end
        end
        self.playerLabels[index]:SetText(text)
        index = index + 1
    end
    
    local text = SUMMARY
    for i = 1, #INSTANCES do
        text = text .. "\n\n|cff"
        local free = frees[i] or 0
        local color = "ffff00"
        if free == count then
            color = "00ff00"
        elseif free == 0 then
            color = "ff0000"
        end
        text = text .. color .. free .. "|r"
    end
    self.playerLabels[#self.playerLabels]:SetText(text)
    
    self.frame:SetWidth(1200)
    self.frame:DoLayout()
    for i = 1, count + 1 do
        self.playerFrames[count + 2 - i]:DoLayout()
    end
end

function GugiInstance:GetOwnInfo()
    local info = {}
    info[1] = UnitName("player") .. " - " .. GetRealmName()
    for i = 1, GetNumSavedInstances() do
        local name, _, _, difficulty, locked, _, _, _, _, difficultyName, _, _ = GetSavedInstanceInfo(i)
        if difficulty == MYTHIC5 and locked then
            for j = 1, #INSTANCES do
                if name == INSTANCES[j] then
                    info[#info + 1] = j
                    break
                end
            end
        end
    end
    return info
end

function GugiInstance:AddInfo(info)
    local currentInfo = {}
    for i = 2, #info do
        currentInfo[tonumber(info[i])] = true
    end
    self.players[info[1]] = currentInfo
end

function GugiInstance:SendSyncRequest()
    self.players = {}
    for i = 1, #self.playerLabels do
        self.playerLabels[i]:SetText(EMPTY_PLAYER)
    end
    SendAddonMessage(CHANNEL_REQUEST, "SYNC", "PARTY")
end

function GugiInstance:SendInfo()    
    local info = self:GetOwnInfo()
    local message = info[1]
    
    for i = 2, #info do
        message = message .. "#" .. info[i]
    end
    SendAddonMessage(CHANNEL_ANSWER, message, "PARTY")
end

function GugiInstance:Command(cmd)
    if self.frame then
        self:SendSyncRequest()
    else
        self:ShowFrame()
    end
end