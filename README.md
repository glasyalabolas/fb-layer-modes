# fb-layer-modes
Simple demo to show how to implement blending modes such as the ones in GIMP.

There are 31 of them implemented, shown here in alphabetic order:
  Addition
  Alpha
  Average
  Brighten
  Brightness
  Burn
  Darken
  DarkenOnly
  Desaturate
  Difference
  Dissolve
  Divide
  Dodge
  Exclusion
  Freeze
  Glow
  GrainExtract
  GrainMerge
  GrayScale
  HardLight
  Heat
  LightenOnly
  Multiply
  Negative
  Overlay
  Reflect
  Screen
  SoftLight
  Stamp
  Substract
  Tint

The 'layer modes.bas' contains a simple demo showing all of them (see the comments in the code for the keybindings)
And 'benchmark.bas' does a simple test to compare the blitter with the equivalent functionality implemented using FB's PUT statement with the custom mode. Only 'Alpha' blending mode is compared, which is the basic alpha composition with support for opacity.

Have fun!
