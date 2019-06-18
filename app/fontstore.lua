local is_number = require ("pleasure.is").number

return {
    default = setmetatable({}, {
        __index = function (store, size)
            assert(is_number(size), "attempt to access default font with non-numerical size")
            local font = love.graphics.newFont(size)
            rawset(store, size, font)
            return font
        end;
    });
}
