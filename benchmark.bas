#include once "inc/platform.bi"
#include once "inc/tgaloader.bi"
#include once "inc/colorproc.bi"
#include once "inc/blendmodes.bi"
#include once "inc/blitter.bi"
#include once "fbgfx.bi"
/'
	Simple benchmark to compare blendedBlit() with its equivalent FB custom PUT statement
	
	Keybindings:
	
	arrow keys - move the source image
	'+' makes the source image less transparent (increases opacity)
	'-' makes the source image more transparent (decreases opacity)
	'0' switch the two implementations
	
	You can use it to measure how many BPS (blits per second) you get with each implementation. You
	have to give it some time to reach a stable result (it uses an exponential moving average for
	computing the average BPS)
	
	On my box, I get these results, using FB custom PUT as the benchmark and the 'star.tga' image. A
	negative percentile means that the implementation is slower than the benchmark, positive means
	faster. In GCC's case, compiler settings are -gen gcc -Wc -O3. I couldn't test it in 32-bit GCC.
	
	Results:
	
							custom PUT				blendedBlit()		%
	32-bit gas	~1000 BPS					~800 BPS				-20
	32-bit GCC	n/a								n/a							n/a
	64-bit GCC	~2600 BPS					~3200 BPS				+20
	
'/
function ema( byval value as double = 0.0, byval period as double = 1.0, byval zero as boolean = false ) as double
	/'
		EMA (Exponential Moving Average) implementation
		
		Used here to compare two implementations of the same blitter (one using mine, the other
		using a FB custom PUT statement)
	'/
	static as double avg
	
	if( zero = true ) then
		avg = 0.0
	end if
	
	dim as double smoothFactor = 2.0 / ( 1.0 + period )	
	avg = avg * ( 1.0 - smoothFactor ) + value * smoothFactor 
	
	return( avg )
end function

function customAlphaBlend( byval source as uinteger, byval dest as uinteger, byval param as any ptr ) as uinteger
	'' this blending function is functionally equivalent to 'bmAlpha' function
	dim as RGBAColor src = cast( uint32, source )
	dim as RGBAColor dst = cast( uint32, dest )
	dim as ubyte opacity = *cast( ubyte ptr, param )
	
	'' apply opacity to the blending function directly
	return rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( src.r - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( src.g - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( src.b - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) )	
end function

'' set a screen mode
dim as integer scrW = 1000, scrH = 600, scrPitch, scrBpp
screenRes( scrW, scrH, 32 )

'' loads an image to blit
dim as fb.image ptr img = fromTGA( "data/star.tga" )

'' loads an image to be used as background 
dim as fb.image ptr dest = imageCreate( scrW, scrH )

bload( "data/back.bmp", dest )

'' this var holds the time it takes to perform one blit
dim as double t

'' position of the center of the image
dim as integer x = scrW shr 1
dim as integer y = scrH shr 1

'' controls the total opacity of the image
dim as ubyte opacity = 255
 
dim as string keyP
dim as boolean test = false

'' initialize ema
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
	
	select case keyP
		case "0"
			test xor= true
		case "+"
			opacity = min( 255, opacity + 1 )
		case "-"
			opacity = max( 0, opacity - 1 )
	end select
	
	'' main render block
	screenLock()
		'' draw background
		put( 0, 0 ), dest, pset
		
		'' small comparison test
		if( test = true ) then
			randomize( 0 )
			t = timer()
			blendedBlit( x - img->width shr 1, y - img->height shr 1, img, , @bmAlpha, opacity )
			t = timer() - t
		else
			t = timer()
			put( x - img->width shr 1, y - img->height shr 1 ), img, custom, @customAlphaBlend, @opacity
			t = timer() - t
		end if
		
	screenUnlock()
	
	'' update ema
	blitsPerSecond = ema( t, 250 )
	
	windowTitle( fbVersion & " - BPS: " & str( int( 1 / blitsPerSecond ) ) & _
		iif( test = true, " using blendedBlit()", " using FB custom PUT" ) & _
		" - Opacity: " & trim( str( opacity ) ) )
	
	sleep( 2 )
loop until( multikey( fb.sc_escape ) )

imageDestroy( dest )
imageDestroy( img )
