-- IncomingGold.lua
-- This addon calculates and displays the total incoming gold from sold auctions,
-- tracks daily income using SavedVariables, and provides an on-screen UI

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

-- Create a frame that will serve as our custom interface
local GoldFrame = CreateFrame("Frame", "GoldFrame", AuctionHouseFrame, "BasicFrameTemplate")
GoldFrame:SetSize(300, 50)  -- Set the size (width, height) as needed
GoldFrame:SetPoint("TOP", AuctionHouseFrame, "TOP", -275, -50)  -- Position it relative to AuctionHouseFrame
GoldFrame:SetFrameStrata("DIALOG")  -- Ensure it's on top of other UI elements

local goldTitleText = GoldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
goldTitleText:SetPoint("TOP", GoldFrame, "TOP", 0, -5)
goldTitleText:SetFont("Fonts\\FRIZQT__.TTF", 12)  -- Adjust font and size here.
goldTitleText:SetText("Incoming Gold")

-- Hide close button
if GoldFrame.CloseButton then
    GoldFrame.CloseButton:Hide()
end
GoldFrame:Hide()  -- Hide it by default

-------------------------------------------------
-- Function to Update Incoming Gold from AH      --
-------------------------------------------------
local function UpdateIncomingGold()
    if not AuctionFrame or not AuctionFrame:IsShown() then 
        DebugPrint("AuctionFrame not shown.")
        return 
    end

    local totalGold = 0
    local numAuctions = GetNumAuctionItems("owner")
    DebugPrint("Number of auctions in owner list: " .. numAuctions)
    
    for i = 1, numAuctions do
        local itemName, texture, count, quality, canUse, level, levelColHeader,
              minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
              bidderFullName, owner, sold = GetAuctionItemInfo("owner", i)
              
        DebugPrint("Auction " .. i .. ": itemName: " .. tostring(itemName) ..
                   ", bidAmount: " .. tostring(bidAmount) ..
                   ", buyoutPrice: " .. tostring(buyoutPrice) ..
                   ", sold flag: " .. tostring(sold))
                   
        -- Only consider this auction sold if bidAmount > 0.
        if bidAmount and bidAmount > 0 then
            totalGold = totalGold + buyoutPrice
            DebugPrint("Auction " .. i .. " is sold (bidAmount > 0). Adding buyoutPrice: " .. buyoutPrice)
        else
            DebugPrint("Auction " .. i .. " is not sold (bidAmount <= 0 or nil).")
        end
    end

    DebugPrint("Total incoming gold calculated: " .. totalGold)

    -- Get today's date
    local today = date("%Y-%m-%d")

    -- Ensure GoldTrackerDB stores today's income properly
    if not GoldTrackerDB.income[today] then
        GoldTrackerDB.income[today] = 0
    end

    -- Calculate new earnings only when totalGold increases
    if totalGold > sessionTotalSales then
        local newSales = totalGold - sessionTotalSales
        sessionTotalSales = totalGold

        GoldTrackerDB.income[today] = GoldTrackerDB.income[today] + newSales
        DebugPrint("Recorded new income of " .. newSales .. " for " .. today)
    end

    -- Fetch today's total earnings
    local earnedToday = GoldTrackerDB.income[today] or 0

    -- Update UI to display both Incoming Gold and Earned Today
    goldText:SetText(GetCoinTextureString(totalGold))
end


local function OnAuctionHouseShow()
    if GoldFrame then
        IncomingGoldFrame:SetParent(GoldFrame)
        IncomingGoldFrame:ClearAllPoints()
        IncomingGoldFrame:SetPoint("TOP", GoldFrame, "TOP", 0, -25)
    else
        DebugPrint("AuctionFrame is nil!")
    end
    UpdateIncomingGold()
end


-- Define an event handler to show/hide the frame
local function OnEvent(self, event, ...)
    DebugPrint("Event triggered: " .. event)
    if event == "AUCTION_HOUSE_SHOW" then
        self:Show()
        OnAuctionHouseShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self:Hide()
    elseif event == "AUCTION_OWNED_LIST_UPDATE" then
        UpdateIncomingGold()
    end
end

-- Set the script for handling events and register the events
GoldFrame:SetScript("OnEvent", OnEvent)
GoldFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
GoldFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")


IncomingGoldFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
IncomingGoldFrame:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
IncomingGoldFrame:SetScript("OnEvent", OnEvent)

if AuctionFrameCompletedAuctions then
    AuctionFrameCompletedAuctions:HookScript("OnShow", function()
        DebugPrint("Completed Auctions tab shown.")
        UpdateIncomingGold()
    end)
else
    DebugPrint("AuctionFrameCompletedAuctions not found.")
end
