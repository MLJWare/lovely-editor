return {
    default = setmetatable({}, {
        __index = function (store, size)
            assert(type(size) == "number", "attempt to access default font with non-numerical size")
            local font = love.graphics.newFont(size)
            rawset(store, size, font)
            return font
        end;
    });
}
