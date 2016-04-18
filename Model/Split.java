package org.nlogo.extensions.string;

import org.nlogo.api.Argument;
import org.nlogo.api.Context;
import org.nlogo.api.DefaultReporter;
import org.nlogo.api.ExtensionException;
import org.nlogo.api.LogoException;
import org.nlogo.api.LogoListBuilder;
import org.nlogo.api.Syntax;

/*
Extension class for splitting strings by #
Call it via: string:split argument
*/
public class Split extends DefaultReporter
{
    public Syntax getSyntax()
    {
        return Syntax.reporterSyntax(
            new int[] {Syntax.StringType()}, Syntax.ListType()
        ) ;
    }

    public Object report(Argument args[], Context context)
        throws ExtensionException, LogoException
    {
        // take the first argument as a string which should be splitted
        String s = args[0].getString();      

        // make an empty list object to hold the new list
        LogoListBuilder list = new LogoListBuilder();
        // iterate over the splitted string, as there are multiple strings
        for ( String temp : s.split("#"))
        {   // add each string to the list
            list.add(temp);
        }
        //return a netlogo logolist
        return list.toLogoList();
    }
}
