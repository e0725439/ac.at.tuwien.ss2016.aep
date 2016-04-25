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

public class ListRank extends DefaultReporter
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
		//list where position shall be found
        LogoList partnerList  = args[0].getList();
		//list containing elements which are looked up in partnerList
	LogoList proposedList = args[1].getList();
		// new list factory
        LogoListBuilder list = new LogoListBuilder();
		//iterate over all elements from the smaller list containing objects which shall be found in partnerlist
	for(int i = 0;  i <= proposedList.size(); i++) {
		//iterate over partnerlist to find element from proposedList
		for(int j = 0; j <= partnerList.size(); j++) {
		//if element from proposedlist found in partnerlist - add position to @param list	if(proposedList.get(i).equals(partnerList.get(j))) {
				list.add(j);
			}	
		}
	}	
	//return list with positions 
	return list.toLogoList();
    }
}
