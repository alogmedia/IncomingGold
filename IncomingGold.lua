-- IncomingGold.lua
-- This addon calculates and displays the total incoming gold from sold auctions,
-- tracks daily income using SavedVariables, and provides an on-screen UI.
-- Updated for Cataclysm 4.4.2 / 40402 Auction House API

local DEBUG = false

local function DebugPrint(msg)
    if DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IncomingGold DEBUG]|r " .. msg)
    end
end

-- Ensure LibStub exists. If not, print an error.
if not LibStub then
    print("|cffff0000GoldTracker Error: LibStub not found! Please install LibDataBroker-1.1 and LibDBIcon-1.0.|r")
    return
end

-- SavedVariables table (declared in your TOC file)
GoldTrackerDB = GoldTrackerDB or { income = {}, expense = {}, minimap = {} }

-- Session variable to track the last recorded total from the Auction House
local sessionTotalSales = 0

-------------------------------------------------
-- Main Frame to Display Current Incoming Gold --
-------------------------------------------------
local IncomingGoldFrame = CreateFrame("Frame", "IncomingGoldFrame", UIParent)
IncomingGoldFrame:SetSize(500, 20)
IncomingGoldFrame:SetPoint("TOP", UIParent, "TOP", 0, 0)

local goldText = IncomingGoldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
goldText:SetAllPoints(IncomingGoldFrame)
goldText:SetFont("Fonts\\FRIZQT__.TTF", 14)  -- Adjust font and size here.
goldText:SetText("Incoming: " .. GetCoinTextureString(0))

-------------------------------------------------
-- Custom GoldFrame Anchored to AuctionHouseFrame --
-------------------------------------------------
-- Note: AuctionHouseFrame is the new main frame in Cataclysm.
local GoldFrame = CreateFrame("Frame", "GoldFrame", AuctionHouseFrame, "BasicFrameTemplate")
GoldFrame:SetSize(300, 50)  -- Set the size (width, height) as needed
GoldFrame:SetPoint("TOP", AuctionHouseFrame, "TOP", -275, -50)  -- Position relative to AuctionHouseFrame
GoldFrame:SetFrameStrata("DIALOG")  -- Ensure it's on top of other UI elements

local goldTitleText = GoldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
goldTitleText:SetPoint("TOP", GoldFrame, "TOP", 0, -5)
goldTitleText:SetFont("Fonts\\FRIZQT__.TTF", 12)  -- Adjust font and size here.
goldTitleText:SetText("Incoming Gold")

-- Hide close button if it exists
if GoldFrame.CloseButton then
    GoldFrame.CloseButton:Hide()
end
GoldFrame:Hide()  -- Hide by default

-------------------------------------------------
-- Function to Update Incoming Gold from Auction House
-------------------------------------------------
local function UpdateIncomingGold()
    -- Ensure the Auction House frame is visible before proceeding.
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then 
        DebugPrint("AuctionHouseFrame not shown.")
        return 
    end

    local totalGold = 0

    -- Check for the new API (C_AuctionHouse). If not available, exit.
    if not C_AuctionHouse or not C_AuctionHouse.GetOwnedAuctions then
        DebugPrint("C_AuctionHouse API not available!")
        return
    end

    -- Retrieve the list of owned auctions using the new API.
    local ownedAuctions = C_AuctionHouse.GetOwnedAuctions() or {}
    DebugPrint("Number of owned auctions: " .. #ownedAuctions)

    -- Loop through each auction and, if it is sold, add its buyoutAmount.
    for i, auction in ipairs(ownedAuctions) do
        DebugPrint("Auction " .. i .. ": bidAmount=" .. tostring(auction.bidAmount) ..
                   ", buyoutAmount=" .. tostring(auction.buyoutAmount) ..
                   ", status=" .. tostring(auction.status))
        -- Here we assume that auction.status == 1 indicates a sold auction.
        if auction.status == 1 and auction.buyoutAmount and auction.buyoutAmount > 0 then
            totalGold = totalGold + auction.buyoutAmount
            DebugPrint("Auction " .. i .. " is sold; adding buyoutAmount: " .. auction.buyoutAmount)
        else
            DebugPrint("Auction " .. i .. " not sold.")
        end
    end

    DebugPrint("Total incoming gold calculated: " .. totalGold)

    -- Get today's date for daily tracking.
    local today = date("%Y-%m-%d")
    if not GoldTrackerDB.income[today] then
        GoldTrackerDB.income[today] = 0
    end

    -- Only record new earnings when totalGold increases.
    if totalGold > sessionTotalSales then
        local newSales = totalGold - sessionTotalSales
        sessionTotalSales = totalGold
        GoldTrackerDB.income[today] = GoldTrackerDB.income[today] + newSales
        DebugPrint("Recorded new income of " .. newSales .. " for " .. today)
    end

    -- Update the on-screen text with the total gold (formatted with coin textures).
    goldText:SetText(GetCoinTextureString(totalGold))
end

-------------------------------------------------
-- Function to Handle Auction House Showing --
-------------------------------------------------
local function OnAuctionHouseShow()
    if GoldFrame then
        -- Parent the IncomingGoldFrame to GoldFrame for proper positioning.
        IncomingGoldFrame:SetParent(GoldFrame)
        IncomingGoldFrame:ClearAllPoints()
        IncomingGoldFrame:SetPoint("TOP", GoldFrame, "TOP", 0, -25)
    else
        DebugPrint("GoldFrame is nil!")
    end
    UpdateIncomingGold()
end

-------------------------------------------------
-- Event Handler --
-------------------------------------------------
local function OnEvent(self, event, ...)
    DebugPrint("Event triggered: " .. event)
    if event == "AUCTION_HOUSE_SHOW" then
        self:Show()
        OnAuctionHouseShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self:Hide()
    elseif event == "OWNED_AUCTIONS_UPDATED" then
        UpdateIncomingGold()
    end
end

-- Set the script for handling events and register events on GoldFrame.
GoldFrame:SetScript("OnEvent", OnEvent)
GoldFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
GoldFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
GoldFrame:RegisterEvent("OWNED_AUCTIONS_UPDATED")

-- Also register events on IncomingGoldFrame.
IncomingGoldFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
IncomingGoldFrame:RegisterEvent("OWNED_AUCTIONS_UPDATED")
IncomingGoldFrame:SetScript("OnEvent", OnEvent)

--[[
-- In previous versions you might have hooked a "Completed Auctions" tab.
-- In Cataclysm the Auction House UI has changed, so this block is commented out.
if AuctionFrameCompletedAuctions then
    AuctionFrameCompletedAuctions:HookScript("OnShow", function()
        DebugPrint("Completed Auctions tab shown.")
        UpdateIncomingGold()
    end)
else
    DebugPrint("AuctionFrameCompletedAuctions not found.")
end
]]--
