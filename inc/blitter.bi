#include once "platform.bi"
#include once "colorproc.bi"
#include once "fbgfx.bi"

sub blendedBlit( _
	byval x as integer, _
	byval y as integer, _
	byval srcBuffer as const fb.image ptr, _
	byval dstBuffer as const fb.image ptr = 0, _
	byval blendFunc as function( byref as RGBAColor, byref as RGBAColor, byval as ubyte = 255, byval as any ptr = 0 ) as uint32, _
	byval opacity as ubyte = 255, _
	byval param as any ptr = 0 )
	
	dim as integer srcStartX = any
	dim as integer srcStartY = any
	dim as integer srcEndX = any
	dim as integer srcEndY = any
	dim as integer dstStartX = any
	dim as integer dstStartY = any
	dim as integer srcPaddingPix = any
	dim as integer dstPaddingPix = any
	dim as integer srcPadding = any
	dim as integer dstPadding = any
	
	dim as integer srcStride = any
	dim as integer dstStride = any
	
	dim as RGBAColor ptr src = any
	dim as RGBAColor ptr dst = any
	
	dim as integer dstBufferWidth = any
	dim as integer dstBufferHeight = any
	dim as integer dstPitch = any 
	dim as integer dstBpp = any
	
	dstStartX = max( 0, x )
	dstStartY = max( 0, y )
	
	srcStartX = max( 0, -x )
	srcStartY = max( 0, -y )
	
	if( dstBuffer = 0 ) then
		'' drawing to the screen
		'' get info on the screen
		screenInfo( dstBufferWidth, dstBufferHeight, , dstBpp, dstPitch )
		
		'' computes size of padding IN PIXELS
		srcPaddingPix = srcBuffer->pitch \ sizeOf( RGBAColor )
		dstPaddingPix = dstPitch \ sizeOf( RGBAColor )
		
		'' pointer to source pixel data (skip header in bytes)
		src = cast( RGBAColor ptr, srcBuffer ) + sizeOf( fb.image ) \ srcBuffer->bpp
					
		'' calculate size of padding, as FB aligns the width of the images to a multiple of 16 bytes
		srcPadding = srcPaddingPix - srcBuffer->width
		dstPadding = dstPaddingPix - dstBufferWidth
					
		'' compute clipping values		
		srcEndX = min( srcBuffer->width - 1, ( ( dstBufferWidth - 1 ) - ( x + srcBuffer->width - 1 ) ) + srcBuffer->width - 1 )
		srcEndY = min( srcBuffer->height - 1, ( ( dstBufferHeight - 1 ) - ( y + srcBuffer->height - 1 ) ) + srcBuffer->height - 1 )
		
		'' calculate the strides
		dstStride = dstPaddingPix - ( srcEndX - srcStartX ) - 1
		srcStride = srcPadding + srcStartX + ( srcBuffer->width - 1 - srcEndX )

		'' offset the destination buffer to its starting position
		dst = screenPtr() + ( ( dstStartY * dstPitch ) + dstStartX * sizeOf( RGBAColor ) )					
	else
		'' drawing to a buffer
		'' computes size of padding IN PIXELS
		srcPaddingPix = srcBuffer->pitch \ sizeOf( RGBAColor )
		dstPaddingPix = dstBuffer->pitch \ sizeOf( RGBAColor )
		
		'' pointer to pixel data (skip header in bytes)
		src = cast( RGBAColor ptr, srcBuffer ) + sizeOf( fb.image ) \ srcBuffer->bpp
		dst = cast( RGBAColor ptr, dstBuffer ) + sizeOf( fb.image ) \ dstBuffer->bpp
		
		'' calculate size of padding, as FB aligns the width of the images to a multiple of 16 bytes
		srcPadding = srcPaddingPix - srcBuffer->width
		dstPadding = dstPaddingPix - dstBuffer->width
		
		'' compute clipping values		
		srcEndX = min( srcBuffer->width - 1, ( ( dstBuffer->width - 1 ) - ( x + srcBuffer->width - 1 ) ) + srcBuffer->width - 1 )
		srcEndY = min( srcBuffer->height - 1, ( ( dstBuffer->height - 1 ) - ( y + srcBuffer->height - 1 ) ) + srcBuffer->height - 1 )
		
		'' calculate the strides
		dstStride = dstPaddingPix - ( srcEndX - srcStartX ) - 1
		srcStride = srcPadding + srcStartX + ( srcBuffer->width - 1 - srcEndX )
		
		'' offset the destination buffer to its starting position
		dst += ( ( dstStartY * ( dstBuffer->pitch \ sizeOf( RGBAColor ) + dstPadding ) ) + dstStartX )						
	end if
		
	'' offset the source buffer to its starting position
	src += ( ( srcStartY * srcPaddingPix ) + srcStartX )
	
	'' the resulting color of the blend function
	dim as RGBAColor result = any
	
	/'
		Renders source buffer into destination buffer, using the currently selected blending
		function
		
		Note that, despite this is a very tight double-nested loop, it's VERY fast, as it accesses the memory
		linearly (which doesn't thrashes the cache), and there's almost no computation performed besides 
		the blending itself, just two sums in	the inner loop, and two more on the outer loop.
		
		Also note that exception code for out-of-bounds cases are not needed, for the clipping takes care of
		that. If the source buffer is entirely out of bounds, the signs for 'srcStartY' and 'srcEndY' become
		swapped, and the outermost for-next loop is entirely skipped.
	'/
	for y as integer = srcStartY to srcEndY
		for x as integer = srcStartX to srcEndX			
			'' apply the blending function			
			*dst = blendFunc( *src, *dst, opacity, param )
						
			'' next pixel
			dst += 1
			src += 1			
		next
		
		'' add the stride to the end of each horizontal scanline
		dst += dstStride
		src += srcStride
	next
end sub
