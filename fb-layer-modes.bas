#include once "inc/platform.bi"
#include once "inc/tgaloader.bi"
#include once "inc/colorproc.bi"
#include once "inc/blendmodes.bi"
#include once "inc/blitter.bi"
#include once "fbgfx.bi"

function ema( byval value as double = 0.0, byval period as double = 1.0, byval zero as boolean = false ) as double
	/'
		EMA (Exponential Moving Average) implementation		
	'/
	static as double avg
	
	if( zero = true ) then
		avg = 0.0
	end if
	
	dim as double smoothFactor = 2.0 / ( 1.0 + period )	
	avg = avg * ( 1.0 - smoothFactor ) + value * smoothFactor 
	
	return( avg )
end function

/'
	This is for the demo purposes. Defines a data structure to group all blending modes
	together so it's easier to swith them at run-time
'/
type blendMode
	public:
		declare constructor()
		declare constructor( _
			byval f as function( byref as RGBAColor, byref as RGBAColor, byval as ubyte = 255, byval as any ptr = 0 ) as uint32, _
			byval p as any ptr = 0, byref n as const string )
			
		func as function( byref as RGBAColor, byref as RGBAColor, byval as ubyte = 255, byval as any ptr = 0 ) as uint32
		as any ptr param = 0
		as string name	
end type

constructor blendMode()
	func = 0
	param = 0
	name = "unknown"
end constructor

constructor blendMode( _
	byval f as function( byref as RGBAColor, byref as RGBAColor, byval as ubyte = 255, byval as any ptr = 0 ) as uint32, _
	byval p as any ptr = 0, byref n as const string )
	
	func = f
	param = p
	name = n
end constructor

'' structure containing all the info needed for each of them
dim as blendMode blendModes( 0 to 30 )

'' controls the total opacity of the image
dim as ubyte opacity = 255
'' controls the 'parameter' of the blender
dim as integer param = 255

dim as tintParams tint = tintParams( 255, rgba( 255, 128, 0, 255 ) )

/'
	Set the needed parameters for each blending mode
	
	A helper macro is used to keep code short, but its straightforward enough
'/
#macro setBlendMode( nm, index, bf, prm )
	with blendModes( index )
		.name = nm
		.func = bf
		.param = prm
	end with
#endmacro

setBlendMode( "Addition", 0, @bmAddition, @param )
setBlendMode( "Alpha", 1, @bmAlpha, @param )
setBlendMode( "Average", 2, @bmAverage, @param )
setBlendMode( "Brighten", 3, @bmBrighten, @param )
setBlendMode( "Brightness", 4, @bmBrightness, @param )
setBlendMode( "Burn", 5, @bmBurn, @param )
setBlendMode( "Darken", 6, @bmDarken, @param )
setBlendMode( "DarkenOnly", 7, @bmDarkenOnly, @param )
setBlendMode( "Desaturate", 8, @bmDesaturate, @param )
setBlendMode( "Difference", 9, @bmDifference, @param )
setBlendMode( "Dissolve", 10, @bmDissolve, @param )
setBlendMode( "Divide", 11, @bmDivide, @param )
setBlendMode( "Dodge", 12, @bmDodge, @param )
setBlendMode( "Exclusion", 13, @bmExclusion, @param )
setBlendMode( "Freeze", 14, @bmFreeze, @param )
setBlendMode( "Glow", 15, @bmGlow, @param )
setBlendMode( "Grain Extract", 16, @bmGrainExtract, @param )
setBlendMode( "Grain Merge", 17, @bmGrainMerge, @param )
setBlendMode( "GrayScale", 18, @bmGrayScale, @param )
setBlendMode( "Hard Light", 19, @bmHardLight, @param )
setBlendMode( "Heat", 20, @bmHeat, @param )
setBlendMode( "Lighten Only", 21, @bmLightenOnly, @param )
setBlendMode( "Multiply", 22, @bmMultiply, @param )
setBlendMode( "Negative", 23, @bmNegative, @param )
setBlendMode( "Overlay", 24, @bmOverlay, @param )
setBlendMode( "Reflect", 25, @bmReflect, @param )
setBlendMode( "Screen", 26, @bmScreen, @param )
setBlendMode( "Soft Light", 27, @bmSoftLight, @param )
setBlendMode( "Stamp", 28, @bmStamp, @param )
setBlendMode( "Substract", 29, @bmSubstract, @param )
setBlendMode( "Tint", 30, @bmTint, @tint )

'' set a screen mode
dim as integer scrW = 1000, scrH = 600, scrPitch, scrBpp
screenRes( scrW, scrH, 32 )

'' loads an image to blit
dim as fb.image ptr img = fromTGA( "data/99605.tga" )

'' loads an image to be used as background 
dim as fb.image ptr dest = imageCreate( scrW, scrH )
bload( "data/back.bmp", dest )

'' position of the center of the screen
dim as integer x = scrW shr 1
dim as integer y = scrH shr 1

'' holds a key press
dim as string keyP

'' current blend mode
dim as integer currBlendMode = 0

dim as double t
dim as double blitsPerSecond = ema( 20, 250, true )

do
	'' get a key press
	keyP = lcase( inkey() )
	
	'' used to move the image
	if( multikey( fb.sc_up ) ) then
		y -= 5	
	end if
	
	if( multikey( fb.sc_down ) ) then
		y += 5	
	end if
	
	if( multikey( fb.sc_left ) ) then
		x -= 5	
	end if
	
	if( multikey( fb.sc_right ) ) then
		x += 5	
	end if
	
	/'
		Some keybindings
		
		'0' - switches between my implementation of the blitter and FB put command
		'+' - increments opacity
		'-' - decrements opacity
		'w' - increases 'parameter'
		'q' - decreases 'parameter'
		'1' and '2' - choose blend mode
		'r' resets opacity and 'param' to 255
		
		Take heed that 'param' is not clamped at all, for some blending functions actually depend on it
		to be negative
	'/
	select case keyP
		case "+"
			opacity = min( 255, opacity + 1 )
		case "-"
			opacity = max( 0, opacity - 1 )
		case "w"
			param += 1
			tint.amount += 1
		case "q"
			param -= 1
			tint.amount -= 1
		case "1"
			currBlendMode = max( 0, currBlendMode - 1 ) 
		case "2"
			currBlendMode = min( ubound( blendModes ), currBlendMode + 1 ) 
		case "r"
			opacity = 255
			param = 255 
			tint.amount = 255
	end select
	
	'' needed for the 'bmDissolve' function, so rnd() returns the same values
	'' with each call. Try commenting this and see what I mean
	randomize( 0 )
	
	'' main render block
	screenLock()
		'' draw background
		put( 0, 0 ), dest, pset
		
		/'
			Blits the image using the currently selected blending mode. Note that the 'dstBuffer' parameter is omitted, so it
			blits to the screen buffer. Try creating a fb.image buffer (with imageCreate() ) and passing it as a parameter to
			the blendedBlit() function to blit in another buffer		
		'/
		t = timer()
		blendedBlit( x - img->width shr 1, y - img->height shr 1, img, , blendModes( currBlendMode ).func, opacity, blendModes( currBlendMode ).param )
		t = timer() - t
	screenUnlock()
	
	blitsPerSecond = ema( t, 250 )
	
	windowTitle( fbVersion & " - Blending mode: " & blendModes( currBlendMode ).name & _
		" - Opacity: " & trim( str( opacity ) ) & " - Parameter: " & trim( str( param ) ) & " - BPS: " & str( int( 1 / blitsPerSecond ) ) )
	
	sleep( 2 )
loop until( multikey( fb.sc_escape ) )

imageDestroy( dest )
imageDestroy( img )
