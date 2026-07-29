function AnimateQuadrants(object, dt, specialcase)

    if object.quadrants[object.currentanimation] then
        --PartyMember animations not nil, updating frame to display
        object.currentframecount = object.currentframecount+ dt * object.animations[object.currentanimation][3]

        --This part handles looping and unlooping animations.
        if math.floor(object.currentframecount) > object.animations[object.currentanimation][2] then

            if object.animations[object.currentanimation][4] then -- if the animation loops:

                object.currentframecount = 1

            else

                local isspecialcase = false

                if specialcase then
                    for animation, proceed in pairs(specialcase) do
                        if animation == object.currentanimation then

                            print(object.name.." animation ended. Changing "..animation.." => "..proceed)

                            object:set_animation(proceed)
                            isspecialcase = true
                            break
                        end
                    end
                end

                if not isspecialcase then

                    object:set_animation(object.defaultanim)
                    object.currentframecount = 1

                end

            end

        end

        if object.quadrants[object.currentanimation] then
            object.currentquadrant = object.quadrants[object.currentanimation][math.floor(object.currentframecount)]
        end

    end

end