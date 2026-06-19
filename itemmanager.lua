ItemManager = Object:extend()

function ItemManager:new(items, itemssubarray)
    self.items  = items
    self.itemsSubArray = itemssubarray
    self.toUse = {}
end

function ItemManager:removeItem(itemIndex, target_member_no, battle)
    --Add the removed item along with the user, the useé into a new array
    self.toUse[#self.toUse+1] = {battle.current_party_member, self.items[itemIndex], target_member_no}

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