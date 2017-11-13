/'
	This union helps us for decomposing a serialized color
	
	Note that the order of the anonymous type inside the union is the actual order in which
	FB stores color information internally
'/
union RGBAcolor
  as uint32    value
  
  type
    as ubyte b
    as ubyte g
    as ubyte r
    as ubyte a
  end type
  
  declare constructor()
  declare constructor( byval rv as ubyte, byval gv as ubyte, byval bv as ubyte, byval av as ubyte )
  declare constructor( byref rhs as uint32 )
  declare operator cast() as uint32
  declare operator let( byref rhs as uint32 )
end union

constructor RGBAcolor()

end constructor

constructor RGBAcolor( byref rhs as uint32 )
	value = rhs
end constructor

constructor RGBAcolor( byval rv as ubyte, byval gv as ubyte, byval bv as ubyte, byval av as ubyte )
	value = rgba( rv, gv, bv, av )
end constructor

operator RGBAcolor.cast() as uint32
	return( value )
end operator

operator RGBAcolor.let( byref rhs as uint32 )
	value = rhs
end operator

'' and some macros that are useful when doing component arithmetic
#define max( a, b )						iif( a > b, a, b )
#define min( a, b )						iif( a < b, a, b )
#define clamp( mn, mx, v )		iif( v < mn, mn, iif( v > mx, mx, v ) )
#define wrap( wrapValue, v )	( ( v ) + wrapValue ) mod wrapValue
