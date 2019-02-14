local band, rshift = bit.band, bit.rshift

return function (hex)
  return band( rshift(hex, 24), 0xFF)/255
       , band( rshift(hex, 16), 0xFF)/255
       , band( rshift(hex,  8), 0xFF)/255
       , band(        hex,      0xFF)/255
end
