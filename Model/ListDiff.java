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
        // use typesafe helper method from
        // org.nlogo.api.Argument to access argument
        LogoList partnerList  = args[0].getList();
	LogoList toReduceList = args[1].getList();
        //String c = args[1].getString();
        
	partnerList.removeAll(toReduceList);

	return partnerList;
    }
}
