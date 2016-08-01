﻿local itemsData
local itemsOnTheGround = {}

-- getting itemCounter and itemsData
addEventHandler("onResourceStart", root,
	function(resourceStarted)
		local itemsResource = getResourceFromName("rsItems")

		if resourceStarted == resource then
			if itemsResource and itemsResource.state == "running" then
				itemsData = exports["rsItems"]:getItems()
			end

			Data.itemCounter = Data.itemCounter or 1

		elseif resourceStarted == itemsResource then
			itemsData = exports["rsItems"]:getItems()
		end
	end
)


function createItem(itemKey, amount)
	if not itemsData then
		outputDebugString("rsItems resource is not running", 2)
		return
	end

	if not itemsData[itemKey] then
		outputDebugString("There is no item with key \"" .. tostring(itemKey) .. "\"", 2)
		return
	end

	local amount = amount or 1

	local item = deepcopy(itemsData[itemKey])

	item.id = Data.itemCounter
	item.amount = amount

	Data.itemCounter = Data.itemCounter + 1

	return item
end

function dropPlayerItem(player, item, pos)
	if not player or not item then
		return
	end

	-- удаляем итем из итемов игрока
	if playerItems[player] then
		for index, playerItem in ipairs(playerItems[player]) do
			if playerItem == item then
				table.remove(playerItems[player], index)
				break
			end
		end
	end

	refreshClientData(player)

	if pos then
		item.droppedTickCount = getTickCount()
		item.object = createObject(item.model or shared.defaultModel, pos.x, pos.y, pos.z + 0.2)
		item.object.scale = item.modelScale or 0.3
		item.object:setData("inventory.itemData", item)
		item.object.frozen = true

		table.insert(itemsOnTheGround, item)

		triggerClientEvent("inventory.onItemDropped", resourceRoot, item)
	end

	-- TODO: placing item near the player

	setPedAnimationForAllExceptPlayer(player, animations.drop.block, animations.drop.anim, -1, false, false, true, false)
end

function giveItemToPlayer(item, player)
	if not item or not player then
		outputDebugString("", 2)
		return
	end

	if not playerItems[player] then
		outputDebugString("", 2)
		return
	end
	
	for _, inventoryItem in ipairs(playerItems[player]) do
		if inventoryItem.key == item.key then
			-- если есть место в стаке
			if inventoryItem.amount < inventoryItem.stack then
				-- количество оставшегося места в стаке
				local difference = inventoryItem.stack - inventoryItem.amount

				-- если итем, который мы хотим положить в стак, вмещается, так и делаем, на этом функция закончена
				if item.amount <= difference then
					inventoryItem.amount = inventoryItem.amount + item.amount
					refreshClientData(player)
					return
				-- если он не вмещается, кладем то, что вмещается в этот стак и идем дальше по циклу
				else
					inventoryItem.amount = inventoryItem.amount + difference
					item.amount = item.amount - difference
				end
			end
		end
	end

	-- получаем массив из новых айтемов (из одного итема 2400 дерева получаем 3 итема 1000 1000 400)
	-- либо получаем массив, состоящий из одного айтема, если ничего фиксить не надо было
	local items = fixItemStacking(item)

	-- раскладываем новые айтемы по инвентарю
	for _, item in ipairs(items) do
		local slot = getEmptySlot(player)
		if slot then
			item.slot = slot
			table.insert(playerItems[player], item)
			refreshClientData(player)
		else
			return
		end
	end

	return true
end

function createItemByKeyForPlayer(key, player, amount)
	if not player then
		return
	end

	if not amount then
		return
	end

	local item = createItem(key, amount)
	if item then
		if not giveItemToPlayer(item, player) then
			outputDebugString("createItemByKeyForPlayer no slots for player " .. tostring(player.name), 2)
		end
	end
end


function refreshClientData(client)
	if not client then
		return
	end

	triggerClientEvent(client, "inventory.refresh", resourceRoot, playerItems[client] or {})
end

function fixItemStacking(item) -- e.g. one wood item with 2400 amount will return 3 items with 1000, 1000, 400 amount (returns {item} even if no changes)
	if not item then
		return
	end

	if not item.stack or not item.amount then
		return
	end

	if item.amount <= item.stack then
		return {item}
	end

	-- amount: 2400
	-- 2 new items with 1000
	local newItems = {}
	for i = 1, math.floor(item.amount / item.stack) do
		local newItem = createItem(item.key, item.stack)
		if not newItem then
			return item
		end

		table.insert(newItems, newItem)
	end

	-- 1 new item with 400
	local remainder = item.amount % item.stack
	if remainder > 0 then
		local newItem = createItem(item.key, remainder)

		table.insert(newItems, newItem)
	end

	return newItems
end

function getEmptySlot(player)
	local items = playerItems[player]
	if not items then
		return
	end

	local occupied = {}
	for _, item in ipairs(items) do
		if item.slot then
			occupied[item.slot] = true
		end
	end

	for i = 1, settings.inventorySize do
		if not occupied[i] then
			return i
		end
	end
end

addCommandHandler("items", 
	function(player, _, itemKey, amount)
		createItemByKeyForPlayer(itemKey, player, tonumber(amount))
	end
)

function getPlayerItemByID(player, id)
	local items = playerItems[player]
	if not items then
		return
	end

	for _, item in ipairs(items) do
		if item.id == id then
			return item
		end
	end
end

function getSlotItem(player, slot)
	local items = playerItems[player]
	if not items then
		return
	end

	for _, item in ipairs(items) do
		if item.slot == slot then
			return item
		end
	end
end

addEventHandler("inventory.onClientAttemptToPickUpItem", resourceRoot,
	function(item)
		if not client then
			return
		end

		for index, itemOnTheGround in ipairs(itemsOnTheGround) do
			if item.id == itemOnTheGround.id then
				if itemOnTheGround.object then
					local distance = getDistanceBetweenPoints3D(client.position, itemOnTheGround.object.position)
					if distance > shared.maxDistanceToPickupItem then
						return
					end
				else
					return
				end

				if giveItemToPlayer(itemOnTheGround, client) then
					itemOnTheGround.object:destroy()
					itemOnTheGround.object = nil

					table.remove(itemsOnTheGround, index)
				end
			end
		end
	end
)

addCommandHandler("s",
	function(player)
		outputChatBox(#playerItems[player])

		for _, item in ipairs(playerItems[player]) do
			if not item.slot then
				outputChatBox(item.id .. " no slot")
			end
		end
	end
)

addEventHandler("inventory.onClientMoveItem", resourceRoot,
	function(itemID, slot)
		if not client then
			return
		end

		local items = playerItems[client]
		if not items then
			return
		end

		local item = getPlayerItemByID(client, itemID)
		if not item then
			return
		end

		local itemToSwapWith = getSlotItem(client, slot)
		if itemToSwapWith == item then
			return
		end

		if not itemToSwapWith then -- just move
			item.slot = slot
		else -- swap/stack
			-- если ключи совпадают, стакаем их
			if itemToSwapWith.key == item.key then
				-- если есть место в стаке
				if itemToSwapWith.amount < itemToSwapWith.stack then
					-- количество оставшегося места в стаке
					local difference = itemToSwapWith.stack - itemToSwapWith.amount

					-- если итем, который мы хотим положить в стак, вмещается, так и делаем
					if item.amount <= difference then
						itemToSwapWith.amount = itemToSwapWith.amount + item.amount
						item.amount = 0

						-- старый итем нужно отправить в небытие
						for index, itemToRemove in ipairs(playerItems[client]) do
							if item == itemToRemove then
								table.remove(playerItems[client], index)
								break
							end
						end
					-- если не вмещается, то кладем то, что вмещается, а остальное остается на месте
					else
						itemToSwapWith.amount = itemToSwapWith.amount + difference
						item.amount = item.amount - difference
					end
				-- если места в стаке нет, то свапаем
				else
					itemToSwapWith.slot = item.slot
					item.slot = slot
				end
			-- если ключи не совпадают, свапаем их
			else
				itemToSwapWith.slot = item.slot
				item.slot = slot
			end
		end

		refreshClientData(client)
	end
)

addEventHandler("inventory.onClientDropItem", resourceRoot,
	function(itemID, groundPos)
		if not client then
			return
		end

		local items = playerItems[client]
		if not items then
			return
		end

		local item = getPlayerItemByID(client, itemID)
		if not item then
			return
		end

		dropPlayerItem(client, item, groundPos)
	end
)