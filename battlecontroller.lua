require "encounter"

local Controller = {}

function Controller:load()
    self.battle = Encounter()
    self.current_state = "BATTLEUI"
    self.Commands = {}
    self.doneNavigating = false
    self.current_party_member = 1
    self:BULLETSCleanup()
end

function Controller:getState() --Return the battle's current state
    return self.current_state
end

function Controller:setState(state) --Set the battle's current state
    self.current_state = state
end

function Controller:getPartyMember() --Return current_party_member index
    return self.current_party_member
end

function Controller:setPartyMember(current_party_member)
    self.current_party_member = current_party_member
end

function Controller:drawBackground()
    self.battle.Bg:draw()
end

function Controller:drawForeground()

    for i = 1, #self.battle.party_members do
        self.battle.party_members[i]:draw()
    end

    for i = 1,#self.battle.enemies do
        if self.battle.enemies[i] then
            self.battle.enemies[i]:draw()
        end
    end

    self.battle.Enemysub:draw(self:getState(), self.battle.enemies)
    for __, sub in pairs(self.battle.Enemysubsubs) do
        sub:draw(self:getState(), self.battle.enemies)
    end
    self.battle.PartyMemberSub:draw(self:getState(), self.battle.enemies)
    self.battle.ItemSub:draw(self:getState(), self.battle.enemies)

    self.battle.Box:draw()

end

function Controller:update(dt)
        for i = 1, #self.battle.enemies do
        if self.battle.enemies[i] then
            self.battle.enemies[i]:update(dt, self:getState(), self.battle.enemies)
        end
    end

    for i = 1, #self.battle.party_members do
        self.battle.party_members[i]:update(dt)
    end

    self.battle.Bg:update(dt)

    Sole:update(dt, self:getState())

    self.battle.Box:update(dt)

    --print(love.mouse.getX().." , "..love.mouse.getY()) --I use this when checking positions in the UI.

    if not self.battle.MUS_Battlemusic:isPlaying() then
        love.audio.play(self.battle.MUS_Battlemusic)
    end
end

function Controller:BULLETSCleanup() --Self-explanotory.
    for i = 1, #self.battle.party_members do
        self.Commands[i] = {}
        self.battle.party_members[i].isdefending = false
        if self.battle.party_members[i].hp > 0 then self.battle.party_members[i]:set_animation("idle") end
        self.battle.UIs[i]:subtext("* A wild battle commentary appeared!")
        self.battle.UIs[i].buttonmode = 1
    end
    self:setState("BATTLEUI")
end

function Controller:setCommand(partymemberindex, n, misc)
    self.Commands[partymemberindex][n] = misc
end

function Controller:runCommand(partymemberindex, n) --For ExecuteCommands()!
    return self.Commands[partymemberindex][n]()
end

function Controller:getCommand(partymemberindex, n) --Check the command type or get the UI subtext
    return self.Commands[partymemberindex][n]
end


--This if else statement is one of the cores of Theta Battle Tool
--It handles a majority of the UI logic and every single UI-related state change
--Do not edit this unless you're CERTAIN you know what you're doing.
--(Or have a backup, like the official one over at https://github.com/sedat-34/Theta-Battle-Tool)
function Controller:heartBeat(key, selected_enemies, enemies_to_attack, actname, actindex)

    local ARR_STATES = self.battle.party_members[self:getPartyMember()].ARR_BUTTON_STATES

    if self:getState() == "BATTLEUI" then --The main battle menu. If you see the five buttons, you're in this state.

        if key == "right" then
            self.battle.UIs[self:getPartyMember()]:changeselect(1)
        elseif key == "left" then
            self.battle.UIs[self:getPartyMember()]:changeselect(-1)
        elseif key == "x" and self:getPartyMember() ~= 1 then
            if self:runCommand(self:getPartyMember()-1, 1) == "ITEMCOMMAND" then
                self.battle.ItemManager:undoAddition()
            end
            self:setState("BATTLEUI")
            self:setCommand(self:getPartyMember(), 1, nil)
            self:setCommand(self:getPartyMember(), 2, nil)
            self.battle.UIs[self:getPartyMember() - 1]:subtext("* A wild battle commentary appeared!")
            self.battle.UIs[self:getPartyMember() - 1]:menuState(Sole, 0, 0, "BATTLEUI", {})
            self.battle.party_members[self:getPartyMember() - 1]:set_animation("idle")
            love.audio.play(SND_SELECT)
            self:setPartyMember(self:getPartyMember() - 1)
        elseif key == "z" then
            self.battle.UIs[self:getPartyMember()]:subtext(nil)
            love.audio.play(SND_SELECT)

            --Quick exception for selecting items versus any submenus with the enemy list
            if ARR_STATES[self.battle.UIs[self:getPartyMember()].buttonmode] == "ITEMUI" then
                if #self.battle.ItemManager.itemsSubArray > 0 then
                    Sole:updatePosArray(self.battle.ItemManager.itemsSubArray)
                    self.battle.UIs[self:getPartyMember()]:menuState(Sole, 631, 471, ARR_STATES[self.battle.UIs[self:getPartyMember()].buttonmode], self.battle.ItemManager.itemsSubArray)
                else
                    self.battle.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
                end
            else
                self.battle.UIs[self:getPartyMember()]:menuState(Sole, 631, 471, ARR_STATES[self.battle.UIs[self:getPartyMember()].buttonmode], Enemysubarray)
            end

            if self:getState() ~= "BATTLEUI" then
                self.battle.party_members[self:getPartyMember()]:set_animation(ARR_STATES[self.battle.UIs[self:getPartyMember()].buttonmode])
            end

            if ARR_STATES[self.battle.UIs[self:getPartyMember()].buttonmode] == "DEFEND" then

                --No extra commands neeed for the party member to defend
                self:setCommand(self:getPartyMember(), 1,
                    function ()
                        return "DEFCOMMAND"
                    end)

                self:setCommand(self:getPartyMember(), 2, self.battle.party_members[self:getPartyMember()].name.." defended!") --Not displayed, necessary for regular flow of program.
                self.doneNavigating = true
                self:setPartyMember(self:getPartyMember() + 1)
            end

        end

    elseif self:getState() == "ATTACKUI" then --This is when you select which enemy to attack

        if key == "x" then
            love.audio.play(SND_SELECT)
            self.battle.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "BATTLEUI", {})
            self.battle.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = self.battle.enemies[Sole.currentmenuposition]
            selected_enemies[self:getPartyMember()] = self.battle.enemies[Sole.currentmenuposition]

            enemies_to_attack[#enemies_to_attack+1] = selected_enemy
            self:setCommand(self:getPartyMember(), 1,

            function ()
                return "ATTACKCOMMAND"
            end)

            self:setCommand(self:getPartyMember(), 2, "* "..self.battle.party_members[self:getPartyMember()].name.." attacked "..selected_enemy.name.."!") --Not displayed, necessary for regular flow of program.
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif self:getState() == "ACTUI" then --This is where you select which enemy to act with
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.battle.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "BATTLEUI", {})
            self.battle.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = self.battle.enemies[Sole.currentmenuposition]
            selected_enemies[self:getPartyMember()] = self.battle.enemies[Sole.currentmenuposition]
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "ACTSUBSUB", self.battle.act_sub_subs[selected_enemy])
            Sole:updatePosArray(self.battle.act_sub_subs[selected_enemy])
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif self:getState() == "ACTSUBSUB" then --The various acts done with an enemy show up in this state
        if key == "x" then
            love.audio.play(SND_SELECT)
            selected_enemy = nil
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "ACTUI", Enemysubarray)
            self.battle.party_members[self:getPartyMember()]:set_animation("idle")

        elseif key == "z" then
            if not actname then actname = {} end
            actname[self:getPartyMember()] = Sole.positions[Sole.currentmenuposition][1]
            actindex[self:getPartyMember()] = Sole.currentmenuposition
            love.audio.play(SND_SELECT)
            print(selected_enemies[self:getPartyMember()].name.." added to queue to be acted with.")

            self:setCommand(self:getPartyMember(), 1,

            function()

                if self:getState() == "COMMANDS" then self.battle.party_members[self:getPartyMember()]:act(selected_enemies[self:getPartyMember()], actname[self:getPartyMember()], self.battle.UIs[self:getPartyMember()]) end
                return "ACTCOMMAND"

            end)

            self:setCommand(self:getPartyMember(), 2, self.battle.act_sub_subs[selected_enemies[self:getPartyMember()]][actindex[self:getPartyMember()]][4](self.battle.party_members))
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif self:getState() == "ITEMUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.battle.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "BATTLEUI", {})
            self.battle.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            self.battle.ItemManager.tempitem = self.battle.items[Sole.currentmenuposition]
            print(self.battle.ItemManager.tempitem.name)
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "MEMBERUI", self.battle.PartyMemberSubArray)
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif self:getState() == "MEMBERUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "ITEMUI", self.battle.ItemSubArray)
            self.battle.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)

            local itemtext = self.battle.ItemManager:generateItemText(Sole.currentmenuposition, self:getPartyMember(), self.battle.party_members)
            self.battle.ItemManager:addItem(Sole.currentmenuposition, self:getPartyMember())

            self:setCommand(self:getPartyMember(), 1,

                function()

                    if self:getState() == "COMMANDS" then self.battle.ItemManager:useItem(self.battle) end
                    return "ITEMCOMMAND" --Functionally the same as an ACTCOMMAND, but labelled seperately for debugging purposes and code cleanliness.

                end)

            self:setCommand(self:getPartyMember(), 2, itemtext)
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif self:getState() == "SPAREUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.battle.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.battle.UIs[self:getPartyMember()]:menuState(Sole, 0, 0, "BATTLEUI", {})
            self.battle.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = self.battle.enemies[Sole.currentmenuposition]
            selected_enemies[self:getPartyMember()] = self.battle.enemies[Sole.currentmenuposition]
            print(selected_enemies[self:getPartyMember()].name.." added to queue to be spared.")

            self:setCommand(self:getPartyMember(), 1,

                function()

                    if self:getState() == "COMMANDS" then
                        self.battle.party_members[self:getPartyMember()]:spare(selected_enemies[self:getPartyMember()])
                        self.battle.party_members[self:getPartyMember()]:set_animation("spare")
                    end

                    return "SPARECOMMAND"

                end)

            self:setCommand(self:getPartyMember(), 2, "* "..self.battle.party_members[self:getPartyMember()].name.." spared "..selected_enemy.name.."!")
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end
    end

    return selected_enemies, enemies_to_attack, actname, actindex
end

return Controller