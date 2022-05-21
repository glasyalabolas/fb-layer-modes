#include once "platform.bi"
#include once "colorproc.bi"
#include once "fbgfx.bi"

/'
	Simple TGA loader.
	It loads a TGA with alpha channel in binary format.
'/
type TGAHeader field = 1 '' Don't use padding
  as ubyte idlength
  as ubyte colormaptype
  as ubyte datatypecode
  as short colormaporigin
  as short colormaplength
  as ubyte colormapdepth
  as short x_origin
  as short y_origin
  as short width
  as short height
  as ubyte bitsperpixel
  as ubyte imagedescriptor
end type

type BGRAFormat32 field = 1 '' Don't use padding
  as ubyte b
  as ubyte g
  as ubyte r
  as ubyte a
end type

  /'
    Loads a TGA file into a raw stream of bytes.
    Currently this function only loads 32-bit uncompressed TGA files.
  '/
function loadTGARaw( fileName as const string ) as any ptr
  '' Define header and pixel formats
  dim as TGAHeader h
  
  dim as uint32 ptr imgData
  dim as integer fileNum = freeFile()
  
  '' Try to open file
  dim as integer result = open( filename for binary access read as fileNum )
  
  if( result = 0 ) then
    '' Everything ok so retrieve header
    get #fileNum, , h
    
    '' Allocates space for data
    imgData = new uint32[ h.width * h.height ]
    
    '' Load pixel data onto image
    get #fileNum, , *imgData, ( h.width * h.height )
    
    close( fileNum )
  end if
  
  return( imgData )
end function

/'
  Loads a TGA file into a fb.image buffer.		
  Currently this loads only 32-bit uncompressed TGA files.		
'/
function fromTGA( fileName as string ) as Fb.image ptr
  '' Define header and pixel formats
  dim as TGAHeader h
  dim as RGBAColor d
  
  dim as uint32 ptr pix
  dim as fb.image ptr imgData
  dim as integer padding
  
  dim as integer fileNum = freeFile()
  
  '' Open file
  dim as integer result = open( filename for binary access read as fileNum )
  
  if( result = 0 ) then
    '' Retrieve header
    get #fileNum, , h
    
    '' Create a fb.image buffer
    imgData = imageCreate( h.width, h.height )
    
    '' Pointer to pixel data				
    pix = cast( ulong ptr, imgData ) + sizeOf( fb.image ) \ imgData->bpp
    
    '' Calculate size of padding, as FB aligns the width of the images to a multiple of 16 bytes
    padding = imgData->pitch \ imgData->bpp - h.width		
    
    '' Loads pixel data onto image
    for y as integer = 0 to h.height - 1
      for x as integer = 0 to h.width - 1
        get #fileNum, , d
        
        *pix = d
        pix += 1
      next
      
      '' Add the padding to the end of each horizontal scanline
      pix += padding
    next
    
    close( fileNum )
  end if
  
  return( imgData )
end function
