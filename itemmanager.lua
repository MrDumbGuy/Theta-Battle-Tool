ItemManager = Object:extend()

function ItemManager:new(items, itemssubarray)
    self.items  = items
    self.tempitem = nil
    self.itemsSubArray = itemssubarray
    self.toUse = {}
    self.useIndex = 1
end

function ItemManager:addItem(target_member_no, current_party_member)
    self.toUse[#self.toUse+1] = {self.tempitem, target_member_no, current_party_member}
end

function ItemManager:useItem()
    --Grab item, user and recipient data from self.toUse[useIndex]
    local itemToUse =  self.toUse[self.useIndex][1]
    local memberToReceive = self.toUse[self.useIndex][2]
    local memberToUse = self.toUse[self.useIndex][3]

    --Animate user to the item use animation
    memberToUse:set_animation(3)

    --Give recipient the appropiate amount of HP

    --Find the used item's index
    local itemIndex
        for i = 1, #self.items do
            if self.items[i] == itemToUse then itemIndex = i break end
        end

    --Recreate the SubArray and items array as if the removed item (index itemIndex) never existed.
        local neoItemsSubarray = self.itemsSubArray
        for i = itemIndex, #self.itemsSubArray-1 do
            neoItemsSubarray[i][1] = self.itemsSubArray[i+1][1]
        end
        self.itemsSubArray = neoItemsSubarray
        self.itemsSubArray[#self.itemsSubArray] = nil

        local neoItems = self.items
        for i = itemIndex, #self.items-1 do
            neoItems[i][1] = self.items[i+1][1]
        end
        self.items = neoItems
        self.items[#self.items] = nil
end