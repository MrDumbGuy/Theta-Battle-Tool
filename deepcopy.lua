function deepCopy(orig, copies, copymetatable)
    copies = copies or {}
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        -- Handle circular references so the function doesn't get stuck in an infinite loop
        if copies[orig] then
            return copies[orig]
        end

        copy = {}
        copies[orig] = copy

        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key, copies)] = deepCopy(orig_value, copies)
        end


        if copymetatable then
           setmetatable(copy, deepCopy(getmetatable(orig), copies))
        end
    else
        copy = orig
    end

    return copy
end