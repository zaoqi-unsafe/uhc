package uu.jazy.core ;

/**
 * Lazy and Functional.
 * Package for laziness and functions as known from functional languages.
 * Written by Atze Dijkstra, atze@cs.uu.nl
 */

/**
 * An application of a Eval to n parameters.
 */
class ApplyN extends Apply
{
	//private static Stat statNew = Stat.newNewStat( "ApplyN" ) ;
	
	protected Object[] pN ;
	
	public ApplyN( Object f, Object[] p )
	{
		//super( f, p.length ) ;
		super( f ) ;
		pN = p ;
		//statNew.nrEvents++ ;
	}
	
    protected void eraseRefs()
    {
    	//function = null ;
    	pN = null ;
    }
    
    public Object[] getBoundParams()
    {
	    if ( pN == null )
	        return Utils.zeroArray ;
	    return pN ;
    }

    public int getNrBoundParams()
    {
	    if ( pN == null )
	        return 0 ;
        return pN.length ;
    }

}
