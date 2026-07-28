ItemManager = Object:extend()

function ItemManager:new(items, itemssubarray)
    self.items = items
    self.tempitem = nil
    self.itemsSubArray = itemssubarray
    self.toUse = {}
end

function ItemManager:addItem(target_member_no, current_party_member)
    self.toUse[#self.toUse+1] = {self.tempitem, target_member_no, current_party_member}
    for i = 1,3 do
        print(self.toUse[#self.toUse][i])
    end
    self.tempitem = nil
end

function ItemManager:generateItemText(target_member_no, user_member_no, party_members)
    print("target_member_no"..target_member_no)
    print("user_member_no"..user_member_no)
    if target_member_no == user_member_no then
        return party_members[user_member_no].name.." used "..self.tempitem.name.." !"
    else
        return party_members[user_member_no].name.." used "..self.tempitem.name.." on "..party_members[target_member_no].name.." !"
    end

end

function ItemManager:useItem(battle)
    --Grab item, user and recipient data from self.toUse[1]
    local itemToUse =  self.toUse[1][1]
    local memberToReceive = battle.party_members[self.toUse[1][2]]
    local memberToUse = battle.party_members[self.toUse[1][3]]

    if itemToUse then

        --Animate user to the item use animation
        memberToUse:set_animation(3)

        --Give recipient the appropiate amount of HP
        memberToReceive:hpUp(itemToUse.hp)

        --Find the used item's index
        local itemIndex
        print(self.items)
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

            table.remove(self.items, itemIndex)

    end

    --Remove the used toUse index.
    table.remove(self.toUse, 1)

end