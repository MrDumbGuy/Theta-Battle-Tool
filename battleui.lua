BattleUi = Object:extend()

function BattleUi:new(name, background, header, buttons, x, y, targetpartymember)
    self.name = name
    self.background = love.graphics.newImage("sprites/battleUI/ui_"..background..".png")
    self.header = love.graphics.newImage("sprites/battleUI/header_"..header..".png")

    self.subtextstr = nil

    local buttonimages = {}

    for i = 1,#buttons do
        buttonimages[i] = love.graphics.newImage("sprites/battleUI/"..buttons[i][1]..".png")
    end

    self.buttonmode = 1
    self.buttonimages = buttonimages
    self.x = x
    self.y = y
    self.targetpartymember = targetpartymember
end

function BattleUi:changeselect(delta)
    --This is used in the illusion of "moving" your selection.
    --In actuality, this variable tracks which sprite to display.
    love.audio.play(SND_MENUMOVE)
    if self.buttonmode + delta < 1 then
        self.buttonmode = 5
    elseif self.buttonmode + delta > 5 then
        self.buttonmode = 1
    else
        self.buttonmode = self.buttonmode + delta
    end
end

function BattleUi:menuState(soul, x, y, currstate, posarray, battle)
    battle.current_state = currstate
    if posarray then
        soul:updatePosArray(posarray)
    else
        soul.x = x
        soul.y = y
    end
end

function BattleUi:subtext(subtext)
    self.subtextstr = subtext
end

function BattleUi:draw(localcurrentstate, members)
    if localcurrentstate == "BATTLEUI" and current_party_member == self.targetpartymember then
        love.graphics.draw(self.background, self.x, self.y, 0, 1.5, 1.5)
        love.graphics.draw(self.buttonimages[self.buttonmode], self.x, self.y, 0, 1.5, 1.5)
        love.graphics.setFont(HPfont)
        love.graphics.print(members[self.targetpartymember].hp, self.x+205, self.y+10, 0, 1, 1)
        love.graphics.print(members[self.targetpartymember].maxhp, self.x+265, self.y+10, 0, 1, 1)
    else
        love.graphics.draw(self.header, self.x, self.y+54, 0, 1.5, 1.5)
        love.graphics.setFont(HPfont)
        love.graphics.print(members[self.targetpartymember].hp, self.x+205, self.y+64, 0, 1, 1)
        love.graphics.print(members[self.targetpartymember].maxhp, self.x+265, self.y+64, 0, 1, 1)
    end
    if self.subtextstr and current_party_member == self.targetpartymember then
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(Battlefont)
        love.graphics.print(self.subtextstr, 218, 771, 0, 1, 1)
    end
end