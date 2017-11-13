#include once "platform.bi"
#include once "colorproc.bi"
#include once "fbgfx.bi"
/'
	Simple TGA loader
	It loads a TGA with alpha channel in binary format
'/
type TGAHeader field = 1 '' don't use padding
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

type BGRAFormat32 field = 1 '' don't use padding
	as ubyte b
	as ubyte g
	as ubyte r
	as ubyte a
end type

function loadTGARaw( byref fileName as const string ) as any ptr
	/'
		Loads a TGA file into a raw stream of bytes
		Currently this function only loads 32-bit uncompressed TGA files
	'/
	
	'' define header and pixel formats
	dim as TGAHeader h
	
	dim as uint32 ptr imgData
	dim as integer fileNum = freeFile()
	
	'' try to open file
	dim as integer result = open( filename for binary access read as fileNum )
	
	if( result = 0 ) then
		'' everything ok so retrieve header
		get #fileNum, , h
		
		'' allocates space for data
		imgData = new uint32[ h.width * h.height ]
		
		'' load pixel data onto image
		get #fileNum, , *imgData, ( h.width * h.height )
		
		close( fileNum )
	end if
	
	return( imgData )
end function

function fromTGA( byref fileName as string ) as fb.image ptr
	/'
		Loads a TGA file into a fb.image buffer		
		Currently this loads only 32-bit uncompressed TGA files		
	'/
	'' define header and pixel formats
	dim as TGAHeader h
	dim as RGBAColor d
	
	dim as uint32 ptr pix
	dim as fb.image ptr imgData
	dim as integer padding
	
	dim as integer fileNum = freeFile()
	
	'' open file
	dim as integer result = open( filename for binary access read as fileNum )
	
	if( result = 0 ) then
		'' retrieve header
		get #fileNum, , h
		
		'' create a fb.image buffer
		imgData = imageCreate( h.width, h.height )
		
		'' pointer to pixel data				
		pix = cast( ulong ptr, imgData ) + sizeOf( fb.image ) \ imgData->bpp
		
		'' calculate size of padding, as FB aligns the width of the images to a multiple of 16 bytes
		padding = imgData->pitch \ imgData->bpp - h.width		
		/'
			loads pixel data onto image
		'/
		for y as integer = 0 to h.height - 1
			for x as integer = 0 to h.width - 1
				get #fileNum, , d
				
				*pix = d
				pix += 1
			next
			
			'' add the padding to the end of each horizontal scanline
			pix += padding
		next
		
		close( fileNum )
	end if
	
	return( imgData )
end function
