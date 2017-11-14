#include once "platform.bi"
#include once "colorproc.bi"
#include once "fbgfx.bi"
/'
	Blending modes to use with the blendedBlit() routine
	
	There are 31 of them (I got sick of coding them by that point XD), listed here in alphabetical order:
	
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
'/

function bmAlpha( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( src.r - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( src.g - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( src.b - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDissolve( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as ubyte c = rnd() * 255
	dim as ubyte prob = *cast( ubyte ptr, param )
	
	if( c >= prob ) then
		return( dst )
	else
		return( rgba( _
			dst.r + ( opacity * ( ( dst.r + ( src.a * ( src.r - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
			dst.g + ( opacity * ( ( dst.g + ( src.a * ( src.g - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
			dst.b + ( opacity * ( ( dst.b + ( src.a * ( src.b - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
			dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )		
	end if
end function

function bmMultiply( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( ( src.r * dst.r ) shr 8 - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( ( src.g * dst.g ) shr 8 - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( ( src.b * dst.b ) shr 8 - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( ( src.a * dst.a ) shr 8 - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDivide( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( clamp( 0, 255, ( ( 256 * dst.r ) \ ( src.r + 1 ) ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( clamp( 0, 255, ( ( 256 * dst.g ) \ ( src.g + 1 ) ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( clamp( 0, 255, ( ( 256 * dst.b ) \ ( src.b + 1 ) ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( clamp( 0, 255, ( ( 256 * dst.a ) \ ( src.a + 1 ) ) ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmScreen( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( ( 255 - ( ( ( 255 - src.r ) * ( 255 - dst.r ) ) shr 8 ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( ( 255 - ( ( ( 255 - src.g ) * ( 255 - dst.g ) ) shr 8 ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( ( 255 - ( ( ( 255 - src.b ) * ( 255 - dst.b ) ) shr 8 ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( ( 255 - ( ( ( 255 - src.a ) * ( 255 - dst.a ) ) shr 8 ) ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmOverlay( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	/'
		Interestingly, according to the GIMP documentation, the Overlay blend mode has a bug, and its implementation
		is equivalent to the Soft Light blend mode.
		See https://docs.gimp.org/2.8/en/gimp-concepts-layer-modes.html#ftn.gimp-layer-mode-bug162395 for details on
		this one.
		This is the Wikipedia Overlay method. See https://en.wikipedia.org/wiki/Blend_modes#Overlay
		
		Basically:
			if dst < 128: dst = ( 2 * src * dst )
			otherwise: dst = 255 - 2 * ( 255 - dst ) * ( 255 - src )
		
		And you also have to alpha composite it, of course.
	'/
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( iif( dst.r < 128, ( 2 * dst.r * src.r ) shr 8, 255 - ( 2 * ( 255 - dst.r ) * ( 255 - src.r ) ) shr 8 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( iif( dst.g < 128, ( 2 * dst.g * src.g ) shr 8, 255 - ( 2 * ( 255 - dst.g ) * ( 255 - src.g ) ) shr 8 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( iif( dst.b < 128, ( 2 * dst.b * src.b ) shr 8, 255 - ( 2 * ( 255 - dst.b ) * ( 255 - src.b ) ) shr 8 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( iif( dst.a < 128, ( 2 * dst.a * src.a ) shr 8, 255 - ( 2 * ( 255 - dst.a ) * ( 255 - src.a ) ) shr 8 ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDodge( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( min( 255, ( dst.r shl 8 ) \ ( ( 255 - src.r ) + 1 ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( min( 255, ( dst.g shl 8 ) \ ( ( 255 - src.g ) + 1 ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( min( 255, ( dst.b shl 8 ) \ ( ( 255 - src.b ) + 1 ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( min( 255, ( dst.a shl 8 ) \ ( ( 255 - src.a ) + 1 ) ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmBurn( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( max( 0, 255 - ( ( ( 255 - dst.r ) shl 8 ) \ ( src.r + 1 ) ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( max( 0, 255 - ( ( ( 255 - dst.g ) shl 8 ) \ ( src.g + 1 ) ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( max( 0, 255 - ( ( ( 255 - dst.b ) shl 8 ) \ ( src.b + 1 ) ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( max( 0, 255 - ( ( ( 255 - dst.a ) shl 8 ) \ ( src.a + 1 ) ) ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmHardLight( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( iif( src.r > 128, max( 0, ( 255 - ( ( ( 255 - 2 * ( src.r - 128 ) ) * ( 255 - dst.r ) ) shr 8 ) ) ), min( 255, ( ( 2 * ( dst.r * src.r ) ) shr 8 ) ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( iif( src.r > 128, max( 0, ( 255 - ( ( ( 255 - 2 * ( src.g - 128 ) ) * ( 255 - dst.g ) ) shr 8 ) ) ), min( 255, ( ( 2 * ( dst.g * src.g ) ) shr 8 ) ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( iif( src.r > 128, max( 0, ( 255 - ( ( ( 255 - 2 * ( src.b - 128 ) ) * ( 255 - dst.b ) ) shr 8 ) ) ), min( 255, ( ( 2 * ( dst.b * src.b ) ) shr 8 ) ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( iif( src.r > 128, max( 0, ( 255 - ( ( ( 255 - 2 * ( src.a - 128 ) ) * ( 255 - dst.a ) ) shr 8 ) ) ), min( 255, ( ( 2 * ( dst.a * src.a ) ) shr 8 ) ) ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmSoftLight( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32	
	'' compute the result of 'screen' blend mode
	dim as ubyte sr = dst.r + ( src.a * ( ( 255 - ( ( ( 255 - src.r ) * ( 255 - dst.r ) ) shr 8 ) ) - dst.r ) ) shr 8 
	dim as ubyte sg = dst.g + ( src.a * ( ( 255 - ( ( ( 255 - src.g ) * ( 255 - dst.g ) ) shr 8 ) ) - dst.g ) ) shr 8
	dim as ubyte sb = dst.b + ( src.a * ( ( 255 - ( ( ( 255 - src.b ) * ( 255 - dst.b ) ) shr 8 ) ) - dst.b ) ) shr 8
	dim as ubyte sa = dst.a + ( src.a * ( ( 255 - ( ( ( 255 - src.a ) * ( 255 - dst.a ) ) shr 8 ) ) - dst.a ) ) shr 8
	
	'' and perform the 'soft light' blending
	return( rgba( _
		dst.r + ( opacity * ( ( sr + dst.r * ( 255 - ( ( 255 - dst.r ) * ( 255 - src.r ) shr 8 ) - sr ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( sg + dst.g * ( 255 - ( ( 255 - dst.g ) * ( 255 - src.g ) shr 8 ) - sg ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( sb + dst.b * ( 255 - ( ( 255 - dst.b ) * ( 255 - src.b ) shr 8 ) - sb ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( sa + dst.a * ( 255 - ( ( 255 - dst.a ) * ( 255 - src.a ) shr 8 ) - sa ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmGrainExtract( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( clamp( 0, 255, dst.r + ( src.a * ( ( dst.r - src.r + 128 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( clamp( 0, 255, dst.g + ( src.a * ( ( dst.g - src.g + 128 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( clamp( 0, 255, dst.b + ( src.a * ( ( dst.b - src.b + 128 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( clamp( 0, 255, dst.a + ( src.a * ( ( dst.a - src.a + 128 ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmGrainMerge( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( clamp( 0, 255, dst.r + ( src.a * ( ( dst.r + src.r - 128 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( clamp( 0, 255, dst.g + ( src.a * ( ( dst.g + src.g - 128 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( clamp( 0, 255, dst.b + ( src.a * ( ( dst.b + src.b - 128 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( clamp( 0, 255, dst.a + ( src.a * ( ( dst.a + src.a - 128 ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDifference( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( abs( src.r - dst.r ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( abs( src.g - dst.g ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( abs( src.b - dst.b ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( abs( src.a - dst.a ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmAddition( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( min( 255, dst.r + ( src.a * ( ( src.r + dst.r ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( min( 255, dst.g + ( src.a * ( ( src.g + dst.g ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( min( 255, dst.b + ( src.a * ( ( src.b + dst.b ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( min( 255, dst.a + ( src.a * ( ( src.a + dst.a ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmSubstract( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( max( 0, dst.r + ( src.a * ( ( dst.r - src.r ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( max( 0, dst.g + ( src.a * ( ( dst.g - src.g ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( max( 0, dst.b + ( src.a * ( ( dst.b - src.b ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( max( 0, dst.a + ( src.a * ( ( dst.a - src.a ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDarkenOnly( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( min( dst.r, src.r ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( min( dst.g, src.g ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( min( dst.b, src.b ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( min( dst.a, src.a ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmLightenOnly( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( max( dst.r, src.r ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( max( dst.g, src.g ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( max( dst.b, src.b ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( max( dst.a, src.a ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmAverage( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( ( ( src.r + dst.r ) shr 1 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( ( ( src.g + dst.g ) shr 1 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( ( ( src.b + dst.b ) shr 1 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( ( ( src.a + dst.a ) shr 1 ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmStamp( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( clamp( 0, 255, dst.r + 2 * src.r - 256 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( clamp( 0, 255, dst.g + 2 * src.g - 256 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( clamp( 0, 255, dst.b + 2 * src.b - 256 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( clamp( 0, 255, dst.a + 2 * src.a - 256 ) - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmGrayScale( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as ubyte avg = ( src.r + src.g + src.b ) \ 3
	
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( avg - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( avg - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( avg - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDesaturate( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as ubyte l = ( 77 * src.r + 153 * src.g + 26 * src.b ) shr 8
	dim as ubyte amount = *cast( ubyte ptr, param )
	
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( ( src.r + ( amount * ( l - src.r ) ) shr 8 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( ( src.g + ( amount * ( l - src.g ) ) shr 8 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( ( src.b + ( amount * ( l - src.b ) ) shr 8 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmNegative( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( max( 0, 255 - src.r ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( max( 0, 255 - src.g ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( max( 0, 255 - src.b ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmBrighten( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as ubyte amount = *cast( ubyte ptr, param )
	
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( min( 255, src.r + amount ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( min( 255, src.g + amount ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( min( 255, src.b + amount ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmDarken( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as ubyte amount = *cast( ubyte ptr, param )
	
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( max( 0, ( src.r * amount ) shr 8 ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( max( 0, ( src.g * amount ) shr 8 ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( max( 0, ( src.b * amount ) shr 8 ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmTint( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as int32 ptr c = cast( int32 ptr, param )

	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( dst.r + ( src.a * ( clamp( 0, 255, ( src.r + *( c ) ) ) - dst.r ) ) shr 8 - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( dst.g + ( src.a * ( clamp( 0, 255, ( src.g + *( c + 1 ) ) ) - dst.g ) ) shr 8 - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( dst.b + ( src.a * ( clamp( 0, 255, ( src.b + *( c + 2 ) ) ) - dst.b ) ) shr 8 - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmBrightness( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	dim as int32 amount = *cast( int32 ptr, param )

	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( clamp( 0, 255, src.r + amount ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( clamp( 0, 255, src.g + amount ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( clamp( 0, 255, src.b + amount ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmReflect( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( min( 255, iif( src.r = 255, 255, ( dst.r * dst.r ) \ ( 255 - src.r ) ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( min( 255, iif( src.g = 255, 255, ( dst.g * dst.g ) \ ( 255 - src.g ) ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( min( 255, iif( src.b = 255, 255, ( dst.b * dst.b ) \ ( 255 - src.b ) ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmGlow( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( ( iif( dst.r = 255, 255, min( 255, ( src.r * src.r ) \ ( 255 - dst.r ) ) ) - dst.r ) ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( ( iif( dst.g = 255, 255, min( 255, ( src.g * src.g ) \ ( 255 - dst.g ) ) ) - dst.g ) ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( ( iif( dst.b = 255, 255, min( 255, ( src.b * src.b ) \ ( 255 - dst.b ) ) ) - dst.b ) ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmExclusion( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( max( 0, 128 - ( ( 2 * ( dst.r - 128 ) * ( src.r - 128 ) ) shr 8 ) ) ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( max( 0, 128 - ( ( 2 * ( dst.g - 128 ) * ( src.g - 128 ) ) shr 8 ) ) ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( max( 0, 128 - ( ( 2 * ( dst.b - 128 ) * ( src.b - 128 ) ) shr 8 ) ) ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmFreeze( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( iif( dst.r = 0, 0, max( 0, 255 - ( ( 255 - src.r ) ^ 2 ) \ dst.r ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( iif( dst.g = 0, 0, max( 0, 255 - ( ( 255 - src.g ) ^ 2 ) \ dst.g ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( iif( dst.b = 0, 0, max( 0, 255 - ( ( 255 - src.b ) ^ 2 ) \ dst.b ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function

function bmHeat( byref src as RGBAColor, byref dst as RGBAColor, byval opacity as ubyte = 255, byval param as any ptr = 0 ) as uint32
	return( rgba( _
		dst.r + ( opacity * ( ( dst.r + ( src.a * ( iif( src.r = 0, 0, max( 0, 255 - ( ( 255 - dst.r ) ^ 2 ) \ src.r ) ) - dst.r ) ) shr 8 ) - dst.r ) shr 8 ), _
		dst.g + ( opacity * ( ( dst.g + ( src.a * ( iif( src.g = 0, 0, max( 0, 255 - ( ( 255 - dst.g ) ^ 2 ) \ src.g ) ) - dst.g ) ) shr 8 ) - dst.g ) shr 8 ), _
		dst.b + ( opacity * ( ( dst.b + ( src.a * ( iif( src.b = 0, 0, max( 0, 255 - ( ( 255 - dst.b ) ^ 2 ) \ src.b ) ) - dst.b ) ) shr 8 ) - dst.b ) shr 8 ), _
		dst.a + ( opacity * ( ( dst.a + ( src.a * ( src.a - dst.a ) ) shr 8 ) - dst.a ) shr 8 ) ) )	
end function
