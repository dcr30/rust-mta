local screenSize = Vector2(guiGetScreenSize())
local isVisible = false

local SLOT_SIZE = 65
local SLOT_SPACING = 10

local HOTBAR_SLOTS_COUNT = 6
local HOTBAR_OFFSET = 10

local INVENTORY_SIZE = 30
local INVENTORY_WIDTH = 6
local INVENTORY_HEIGHT = 5

local inventoryWidth
local inventoryHeight
local inventoryX
local inventoryY

local INVENTORY_HEADER = 40

local slots = {}

local function createSlot(x, y, hotbarIndex)
    local slot = {}

    slot.x = x
    slot.y = y
    slot.hotbarIndex = hotbarIndex

    table.insert(slots, slot)
    slot.id = #slots
end

local function drawSlots()
    if isVisible then
        dxDrawRectangle(0, 0, screenSize.x, screenSize.y, tocolor(0, 0, 0, 200))
        dxDrawRectangle(inventoryX - SLOT_SPACING, inventoryY - INVENTORY_HEADER, inventoryWidth + SLOT_SPACING * 2, 
            inventoryHeight + INVENTORY_HEADER + SLOT_SPACING, tocolor(50, 50, 50))
        dxDrawText("INVENTORY", inventoryX, inventoryY - INVENTORY_HEADER + 5)
    end
    local mx, my = getCursorPosition()
    if not mx then
        mx, my = 0, 0
    else
        mx, my = mx * screenSize.x, my * screenSize.y
    end
    for i, slot in ipairs(slots) do
        if isVisible or slot.hotbarIndex then
            local color = tocolor(30, 30, 30, 230)
            if mx > slot.x and mx < slot.x + SLOT_SIZE and 
                my > slot.y and my < slot.y + SLOT_SIZE 
            then
                color = tocolor(40, 40, 40, 230)
            end
            dxDrawRectangle(slot.x, slot.y, SLOT_SIZE, SLOT_SIZE, color)
            if slot.hotbarIndex then
                dxDrawText(slot.hotbarIndex, slot.x + 2, slot.y)
            end
        else
            return
        end
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function ()
    inventoryWidth = (SLOT_SIZE + SLOT_SPACING) * HOTBAR_SLOTS_COUNT - SLOT_SPACING
    inventoryX = screenSize.x / 2 - inventoryWidth / 2
    local hotbarY = screenSize.y - SLOT_SIZE - HOTBAR_OFFSET
    for i = 1, HOTBAR_SLOTS_COUNT do
        createSlot(inventoryX + (i - 1) * (SLOT_SIZE + SLOT_SPACING), hotbarY, i)
    end

    -- Основные слоты
    local sx = inventoryX
    inventoryHeight = (SLOT_SIZE + SLOT_SPACING) * INVENTORY_HEIGHT - SLOT_SPACING
    inventoryY = screenSize.y / 2 - inventoryHeight / 2
    local sy = inventoryY
    for i = 1, INVENTORY_SIZE do
        createSlot(sx, sy)
        sx = sx + SLOT_SIZE + SLOT_SPACING
        if i % INVENTORY_WIDTH == 0 then
            sx = inventoryX
            sy = sy + SLOT_SIZE + SLOT_SPACING
        end
    end

    addEventHandler("onClientRender", root, drawSlots)
end)

function setVisible(visible)
    if not not visible == isVisible then
        return
    end
    isVisible = not not visible

    showCursor(visible)
end

bindKey("i", "down", function ()
    setVisible(not isVisible)
end)