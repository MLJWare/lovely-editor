local bor, band, lshift = bit.bor, bit.band, bit.lshift

return function (r, g, b, a)
  return bor( lshift(band(r*255, 0xFF), 24)
            , lshift(band(g*255, 0xFF), 16)
            , lshift(band(b*255, 0xFF),  8)
            ,        band(a*255, 0xFF)    )
end
