package org.nlogo.extensions.string;

import org.nlogo.api.Argument;
import org.nlogo.api.Context;
import org.nlogo.api.DefaultReporter;
import org.nlogo.api.ExtensionException;
import org.nlogo.api.LogoException;
import org.nlogo.api.LogoListBuilder;
import org.nlogo.api.Syntax;
import org.nlogo.api.LogoList;
import java.util.List;

public class ListDiff extends DefaultReporter
{
    // take one string as input, report a list 
    
    public Syntax getSyntax()
    {
        return Syntax.reporterSyntax(
            new int[] {Syntax.StringType()}, Syntax.ListType()
        ) ;
    }
	
    public Object report(Argument args[], Context context)
        throws ExtensionException, LogoException
    {
	//list containing partner id-s
     LogoList partnerList  = args[0].getList();
	//list which shall be removed from the partnerlist
	LogoList toReduceList = args[1].getList();
	        
	partnerList.removeAll(toReduceList);
	//return partnerList without elements contained in toReduceList
	return partnerList;
    }
}
