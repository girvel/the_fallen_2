local colors = {}

colors.white = Vector.hex("ededed")
colors.white_dim = Vector.hex("2a3e34")
colors.golden = Vector.hex("cfa867")
colors.red = Vector.hex("99152c")
colors.red_high = Vector.hex("e7573e")
colors.green_high = Vector.hex("c3e06c")
colors.green_dim = Vector.hex("5d863f")
colors.black = Vector.hex("191919")
colors.blue_high = Vector.hex("799890")

Ldump.mark(colors, {}, ...)
return colors
