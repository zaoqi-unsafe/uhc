package uu.jazy.core ;

/**
 * Lazy and Functional.
 * Package for laziness and functions as known from functional languages.
 * Written by Atze Dijkstra, atze@cs.uu.nl
 */

import java.util.* ;
import java.io.* ;

/**
 * Function accepting/expecting 3 parameter(s).
 * @see uu.jazy.core.Function
 */
public abstract class Function3 extends Function
{
    public Function3( )
    {
        nrParams = 3 ;
    }
    
    public Function3( String nm )
    {
        this() ;
        setName ( nm ) ;
    }
    
    public Function3( Function prev, String nm )
    {
        this( prev.getName() + "." + nm ) ;
    }
        
    abstract protected Object eval3( Object v1, Object v2, Object v3 ) ;
    
    public Apply apply1( Object v1 )
    {
        return new Apply1F3( this, v1 ) ;
    }
    
    public Apply apply2( Object v1, Object v2 )
    {
        return new Apply2F3( this, v1, v2 ) ;
    }
    
    public Apply apply3( Object v1, Object v2, Object v3 )
    {
        return new Apply3F3( this, v1, v2, v3 ) ;
    }
    
    public Apply apply4( Object v1, Object v2, Object v3, Object v4 )
    {
        return apply3( v1, v2, v3 ).apply1( v4 ) ;
    }
    
    public Apply apply5( Object v1, Object v2, Object v3, Object v4, Object v5 )
    {
        return apply3( v1, v2, v3 ).apply2( v4, v5 ) ;
    }
    
}

class Apply1F3 extends Apply1
{
	public Apply1F3( Object f, Object p1 )
	{
		super( f, p1 ) ;
		nrNeededParams = 2 ;
	}
	
    /*
    protected Object eval1( Object v1 )
    {
        return apply1( v1 ) ;
    }
    
    protected Object eval2( Object v1, Object v2 )
    {
        return ((Function3)funcOrVal).eval3( p1, v1, v2 ) ;
    }
    */
    
    public Apply apply1( Object v1 )
    {
        return new Apply2F3( funcOrVal, p1, v1) ;
        //return new Apply1A1F3( this, v1) ;
    }
    
    public Apply apply2( Object v1, Object v2 )
    {
        return new Apply3F3( funcOrVal, p1, v1, v2) ;
        /*
        return new Apply2( this, v1, v2 )
        {
            protected void evalSet( )
            {
                Apply1 app = ((Apply1)funcOrVal) ;
                funcOrVal =
                    ((Function)app.funcOrVal)
                        .eval3
                            ( app.p1
                            , p1
                            , p2
                            ) ;
                p1 = p2 = null ;
            }
        } ;
        */
    }
    
}

/*
class Apply1A1F3 extends Apply1
{
    public Apply1A1F3( Object f, Object p1 )
    {
        super( f, p1 ) ;
		nrNeededParams = 1 ;
    }
    
    protected Object eval1( Object v1 )
    {
        Apply1 app = ((Apply1)funcOrVal) ;
        return
            ((Function)app.funcOrVal)
                .eval3
                    ( app.p1
                    , p1
                    , v1
                    ) ;
    }

    public Apply apply1( Object v1 )
    {
        return new Apply1( this, v1 )
        {
            protected void evalSet( )
            {
                Apply1 app    = ((Apply1)funcOrVal) ;
                Apply1 appBef = ((Apply1)app.funcOrVal) ;
                funcOrVal =
                    ((Function)appBef.funcOrVal)
                        .eval3
                            ( appBef.p1
                            , app.p1
                            , p1
                            ) ;
                p1 = null ;
            }
        } ;
    }
}
*/

class Apply2F3 extends Apply2
{
	public Apply2F3( Object f, Object p1, Object p2 )
	{
		super( f, p1, p2 ) ;
		nrNeededParams = 1 ;
	}
	
    /*
    protected Object eval1( Object v1 )
    {
        return ((Function3)funcOrVal).eval3( p1, p2, v1 ) ;
    }
    */
    
    public Apply apply1( Object v1 )
    {
        return new Apply3F3( funcOrVal, p1, p2, v1) ;
        /*
        return new Apply1( this, v1 )
        {
            protected void evalSet( )
            {
                Apply2 app = ((Apply2)funcOrVal) ;
                funcOrVal =
                    ((Function)app.funcOrVal)
                        .eval3
                            ( app.p1
                            , app.p2
                            , p1
                            ) ;
                p1 = null ;
            }
        } ;
        */
    }
    
}

class Apply3F3 extends Apply3
{
	public Apply3F3( Object f, Object p1, Object p2, Object p3 )
	{
		super( f, p1, p2, p3 ) ;
	}
	
    protected void evalSet()
    {
        funcOrVal = ((Function3)funcOrVal).eval3( p1, p2, p3 ) ;
        p1 = p2 = p3 = null ;
    }
    
}

