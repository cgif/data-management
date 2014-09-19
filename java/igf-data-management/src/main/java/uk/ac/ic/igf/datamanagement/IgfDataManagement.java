package uk.ac.ic.igf.datamanagement;

import org.apache.log4j.Logger;
import java.util.Arrays;
import uk.ac.ic.igf.datamanagement.cmd.Command;

/**
 * This file is part of IgfDataManagement.
 *
 * IgfDataManagement is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * NxtGenUtils is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with NxtGenUtils.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Created by IntelliJ IDEA.
 * User: mmuelle1
 * Date: 21-Oct-2011
 * Time: 13:52:21
 */

/**
 * Main class that facilitates command line usage of NxtGenUtils Command classes.
 *
 * @author Michael Mueller
 */
public class IgfDataManagement {

    /**
     * the log4j logger
     */
    private static Logger logger = Logger.getLogger(NxtGenUtils.class);

    public static String usage =
            "USAGE: java -jar NxtGenUtils.jar <command_name> <command_arguments>\n" +
                    "\n" +
                    "Commands:" +
                    "\n" +
                    "BS-seq\n" +
                    "   PostProcessBSMapping\n" +
                    "   FilterBSMapping\n" +
                    "   ProfileMethylation\n" +
                    "\n" +
                    "Phasing\n" +
                    "   PhaseMapping\n" +
                    "\n" +
                    "Other\n" +
                    "   ClipOverlappingReadPairs\n" +
                    "   CountReads\n" +
                    "   SubstractBam\n" +
                    "   ClipPrimerSequences\n" +
                    "   GatherGatkBqsrReports\n" +
                    "";

    /**
     * Creates a Command instance specified by the command_name argument
     * and calls the run() method on the Command instance to execute the
     * command with the respective command rguments.
     *
     * @param args the command arguments
     */
    public static void main(String[] args) {

        //log error and exit if no command name specified
        if(args.length == 0){
            System.out.println(usage);
            logger.error("Required argument 'command_name' missing.");
            System.exit(1);
        }

        //get command name
        String className = args[0];

        //get command arguments
        String[] cmdArgs = Arrays.copyOfRange(args, 1, args.length);

        //create Command instance and execute command
        try {
            Command cmd = (Command)Class.forName("org.nxtgenutils.cmd." + className).newInstance();

            //log error and exit if no command arguments specified
            if(args.length == 1){
                System.out.println(usage);
                System.out.println("ERROR: Command arguments missing.");
                System.out.println("");
                System.out.println(cmd.getUsage());
                System.exit(1);
            }

            cmd.run(cmdArgs);



        } catch (InstantiationException e) {
            logger.error("Exception while trying to execute command: " + e.getMessage());
        } catch (IllegalAccessException e) {
            logger.error("Exception while trying to execute command: " + e.getMessage());
        } catch (ClassNotFoundException e) {
            System.out.println(usage);
            logger.error("Unknown command: " + args[0]);
            System.exit(1);
        }



    }

}
