#include once "platform.bi"
#include once "colorproc.bi"
#include once "fbgfx.bi"

sub blendedBlit( _
  x as integer, y as integer, srcBuffer as const Fb.Image ptr, dstBuffer as const Fb.Image ptr = 0, _
  func as blendFunc, opacity as ubyte = 255, param as any ptr = 0 )
  
  dim as RGBAColor ptr src = any, dst = any
  
  dim as integer _
    dstBufferWidth = any, dstBufferHeight = any, dstPitch = any, dstBpp = any
  
  dim as integer _
    srcEndX = any, srcEndY = any, _
    srcPaddingPix = any, dstPaddingPix = any, _
    srcPadding = any, dstPadding = any, _
    srcStride = any, dstStride = any
  
  dim as integer _
    dstStartX = max( 0,  x ), dstStartY = max( 0,  y ), _
    srcStartX = max( 0, -x ), srcStartY = max( 0, -y )
  
  if( dstBuffer = 0 ) then
    '' Drawing to the screen
    '' Det info on the screen
    screenInfo( dstBufferWidth, dstBufferHeight, , dstBpp, dstPitch )
    
    '' Compute size of padding IN PIXELS
    srcPaddingPix = srcBuffer->pitch \ sizeOf( RGBAColor )
    dstPaddingPix = dstPitch \ sizeOf( RGBAColor )
    
    '' Pointer to source pixel data (skip header in bytes)
    src = cast( RGBAColor ptr, srcBuffer ) + sizeOf( Fb.Image ) \ srcBuffer->bpp
    
    '' Calculate size of padding, as FB aligns the width of the images to a multiple of 16 bytes
    srcPadding = srcPaddingPix - srcBuffer->width
    dstPadding = dstPaddingPix - dstBufferWidth
    
    '' Compute clipping values		
    srcEndX = min( srcBuffer->width - 1, ( ( dstBufferWidth - 1 ) - ( x + srcBuffer->width - 1 ) ) + srcBuffer->width - 1 )
    srcEndY = min( srcBuffer->height - 1, ( ( dstBufferHeight - 1 ) - ( y + srcBuffer->height - 1 ) ) + srcBuffer->height - 1 )
    
    '' Calculate the strides
    dstStride = dstPaddingPix - ( srcEndX - srcStartX ) - 1
    srcStride = srcPadding + srcStartX + ( srcBuffer->width - 1 - srcEndX )
    
    '' Offset the destination buffer to its starting position
    dst = screenPtr() + ( ( dstStartY * dstPitch ) + dstStartX * sizeOf( RGBAColor ) )					
  else
    '' Drawing to a buffer
    '' Computes size of padding IN PIXELS
    srcPaddingPix = srcBuffer->pitch \ sizeOf( RGBAColor )
    dstPaddingPix = dstBuffer->pitch \ sizeOf( RGBAColor )
    
    '' Pointer to pixel data (skip header in bytes)
    src = cast( RGBAColor ptr, srcBuffer ) + sizeOf( Fb.Image ) \ srcBuffer->bpp
    dst = cast( RGBAColor ptr, dstBuffer ) + sizeOf( Fb.Image ) \ dstBuffer->bpp
    
    '' Calculate size of padding, as FB aligns the width of the images to a multiple of 16 bytes
    srcPadding = srcPaddingPix - srcBuffer->width
    dstPadding = dstPaddingPix - dstBuffer->width
    
    '' Compute clipping values		
    srcEndX = min( srcBuffer->width - 1, ( ( dstBuffer->width - 1 ) - ( x + srcBuffer->width - 1 ) ) + srcBuffer->width - 1 )
    srcEndY = min( srcBuffer->height - 1, ( ( dstBuffer->height - 1 ) - ( y + srcBuffer->height - 1 ) ) + srcBuffer->height - 1 )
    
    '' Calculate the strides
    dstStride = dstPaddingPix - ( srcEndX - srcStartX ) - 1
    srcStride = srcPadding + srcStartX + ( srcBuffer->width - 1 - srcEndX )
    
    '' Offset the destination buffer to its starting position
    dst += ( ( dstStartY * ( dstBuffer->pitch \ sizeOf( RGBAColor ) + dstPadding ) ) + dstStartX )						
  end if
  
  '' Offset the source buffer to its starting position
  src += ( ( srcStartY * srcPaddingPix ) + srcStartX )
  
  '' The resulting color of the blend function
  dim as RGBAColor result = any
  
  /'
    Renders source buffer into destination buffer, using the currently selected blending
    function.
    
    Note that, despite this is a very tight double-nested loop, it's VERY fast, as it accesses the memory
    linearly (which doesn't thrashes the cache), and there's almost no computation performed besides 
    the blending itself, just two sums in	the inner loop, and two more on the outer loop.
    
    Also note that exception code for out-of-bounds cases are not needed, for the clipping takes care of
    that. If the source buffer is entirely out of bounds, the signs for 'srcStartY' and 'srcEndY' become
    swapped, and the outermost for-next loop is entirely skipped.
  '/
  for y as integer = srcStartY to srcEndY
    for x as integer = srcStartX to srcEndX			
      '' Apply the blending function			
      *dst = func( *src, *dst, opacity, param )
      
      '' Next pixel
      dst += 1
      src += 1			
    next
    
    '' Add the stride to the end of each horizontal scanline
    dst += dstStride
    src += srcStride
  next
end sub
