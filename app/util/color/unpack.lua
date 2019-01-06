local band, rshift = bit.band, bit.rshift
return function (rgba)
  return band(rshift(rgba, 24), 0xFF)/255
       , band(rshift(rgba, 16), 0xFF)/255
       , band(rshift(rgba,  8), 0xFF)/255
       , band(       rgba     , 0xFF)/255
end
