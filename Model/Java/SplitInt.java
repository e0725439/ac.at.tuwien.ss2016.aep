package org.nlogo.extensions.string;

import org.nlogo.api.Argument;
import org.nlogo.api.Context;
import org.nlogo.api.DefaultReporter;
import org.nlogo.api.ExtensionException;
import org.nlogo.api.LogoException;
import org.nlogo.api.LogoListBuilder;
import org.nlogo.api.Syntax;

/* splits a string into a int list by a given argument
*  call it via split-int argument1 argument2
*/
public class SplitInt extends DefaultReporter
{
    // take two strings as input, report a list 
    
    public Syntax getSyntax()
    {
        return Syntax.reporterSyntax(
            new int[] {Syntax.StringType(), Syntax.StringType()}, Syntax.ListType()
        ) ;
    }

    public Object report(Argument args[], Context context)
        throws ExtensionException, LogoException
    {
        // first argument is a concatenated string
        String line  = args[0].getString();
        // second argument is the splitter
        String splitter  = args[1].getString();
        

        // make an empty list object to hold the new list
        LogoListBuilder list = new LogoListBuilder();
        // iterate over the splitted string
        for ( String temp : line.split(splitter))
        {   
            // add temp as int to the list
            list.add(Integer.parseInt(temp));
        }
        return list.toLogoList();
    }
}
