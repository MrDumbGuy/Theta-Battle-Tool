BattleUi = Object:extend()

function BattleUi:new(name, background, header, buttons, x, y, targetpartymember, sheetimage, sheetdata)
    self.name = name
    self.sheetimage = sheetimage
    self.sheetwidth = sheetdata.meta.size.w
    self.sheetheight = sheetdata.meta.size.h

    local bgquaddata = sheetdata.frames["ui_"..background..".png"].frame
    self.backgroundquad = love.graphics.newQuad(bgquaddata.x, bgquaddata.y, bgquaddata.w, bgquaddata.h, sheetdata.meta.size.w, sheetdata.meta.size.h)
    local headerquaddata = sheetdata.frames["header_"..header..".png"].frame
    self.headerquad = love.graphics.newQuad(headerquaddata.x, headerquaddata.y, headerquaddata.w, headerquaddata.h, sheetdata.meta.size.w, sheetdata.meta.size.h)

    self.subtextstr = nil

    local buttonquads = {}

    for i = 1,#buttons do
        local localquad = sheetdata.frames[buttons[i][1]..".png"].frame
        buttonquads[i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetdata.meta.size.w, sheetdata.meta.size.h)
    end

    self.buttonmode = 1
    self.buttonquads = buttonquads
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

function BattleUi:menuState(soul, x, y, currstate, posarray)
    Controller:setState(currstate)
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
    if localcurrentstate == "BATTLEUI" and Controller:getPartyMember() == self.targetpartymember then
        love.graphics.draw(self.sheetimage, self.backgroundquad, self.x, self.y, 0, 1.5, 1.5)
        love.graphics.draw(self.sheetimage, self.buttonquads[self.buttonmode], self.x, self.y, 0, 1.5, 1.5)
        love.graphics.setFont(HPfont)
        love.graphics.print(members[self.targetpartymember].hp, self.x+205, self.y+10, 0, 1, 1)
        love.graphics.print(members[self.targetpartymember].maxhp, self.x+265, self.y+10, 0, 1, 1)
    else
        love.graphics.draw(self.sheetimage, self.headerquad, self.x, self.y+54, 0, 1.5, 1.5)
        love.graphics.setFont(HPfont)
        love.graphics.print(members[self.targetpartymember].hp, self.x+205, self.y+64, 0, 1, 1)
        love.graphics.print(members[self.targetpartymember].maxhp, self.x+265, self.y+64, 0, 1, 1)
    end
    if self.subtextstr and Controller:getPartyMember() == self.targetpartymember then
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(Battlefont)
        love.graphics.print(self.subtextstr, 218, 771, 0, 1, 1)
    end
end