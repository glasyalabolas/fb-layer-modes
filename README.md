# fb-layer-modes
Simple demo to show how to implement layer blending modes such as the ones found in the GIMP.

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
And 'benchmark.bas' does a simple test to compare the blitter with the equivalent functionality implemented using FB's PUT statement with the custom mode. Only 'Alpha' blending mode is compared, which is the basic alpha compositing with support for opacity.

![Imagen27](https://user-images.githubusercontent.com/33088504/169664866-a40fc37d-4f5e-4580-82ae-8e97515ab187.png)

Have fun!
