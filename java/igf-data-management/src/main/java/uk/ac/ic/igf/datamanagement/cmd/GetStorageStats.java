package uk.ac.ic.igf.datamanagement.cmd;

/**
 * This file is part of igf-data-management.
 * <p/>
 * igf-data-management is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * <p/>
 * igf-data-management is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * <p/>
 * You should have received a copy of the GNU General Public License
 * along with igf-data-management.  If not, see <http://www.gnu.org/licenses/>.
 * <p/>
 * Created by IntelliJ IDEA.
 * User: mmuelle1
 * Date: 19/09/14
 * Time: 15:15
 */

import org.apache.log4j.Logger;
import uk.ac.ic.igf.datamanagement.Configuration;
import uk.ac.ic.igf.datamanagement.EmailAccount;
import uk.ac.ic.igf.datamanagement.FileFormat;
import uk.ac.ic.igf.datamanagement.IgfDataManagement;
import uk.ac.ic.igf.datamanagement.storage.StorageResource;
import uk.ac.ic.igf.datamanagement.storage.StorageResourceUsageRetriever;
import uk.ac.ic.igf.datamanagement.storage.StorageResourceUsageWriter;
import uk.ac.ic.igf.datamanagement.storage.impl.SshStorageResourceUsageRetriever;
import uk.ac.ic.igf.datamanagement.storage.impl.StorageResourceUsageEmailWriter;
import uk.ac.ic.igf.datamanagement.storage.impl.StorageResourceUsagePrintWriter;

import java.io.File;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Provides access to classes to query and track resource usage.
 *
 * @author Michael Mueller
 */
public class GetStorageStats extends AbstractCommand {

    private static Logger logger = Logger.getLogger(GetStorageStats.class);

    public GetStorageStats() {
        usage = "Arguments for GetStorageStats\n" +
                "\n" +
                "    -c --config <path_to_configuration_json>\n" +
                "    -p --print [<path_to_output_file>, default STDOUT]\n" +
                "   [-e --email <email_account_name>]\n" +
                "   [-r --emailrecipient <recipient_email_address>,...]\n" +
                "   [-u --updatedb]\n" +
                "   [-l --plot <path_to_output_directory, default current working directory>]\n" +
                "   [-f --plotformat <pdf|jpg|png, default pdf>]\n";
    }

    /**
     * @param args
     */
    public void run(String[] args) {

        String jsonConfigPath = null;
        boolean print = false;
        boolean email = false;
        String emailAccountName = null;
        Set<String> emailRecipients = new HashSet<>();
        String printOutputFilePath = "stdout";
        boolean update = false;
        boolean plot = false;
        String plotOutputDirectoryPath = null;
        FileFormat plotFormat = FileFormat.PDF;
        boolean exception = false;

        try {

            for (int i = 0; i < args.length; i++) {

                if (args[i].startsWith("--config") || args[i].equals("-c")) {

                        if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                            jsonConfigPath = args[i + 1];
                            i++;
                        } else {
                            System.out.println(args.length + "<=" + i + 1);
                            logger.error("Missing value for command line argument: " + args[i]);
                            exception = true;
                        }


                } else if (args[i].equals("--print") || args[i].equals("-p")) {

                    print = true;

                    //check if argument value present
                    if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        printOutputFilePath = args[i + 1];
                        i++;
                    } else {
                        printOutputFilePath = "stdout";
                    }

                } else if (args[i].startsWith("--update") || args[i].equals("-u")) {

                    update = true;

                } else if (args[i].startsWith("--email") || args[i].equals("-e")) {

                    email = true;

                    //check if argument value present
                    if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        emailAccountName = args[i + 1];
                        i++;
                    } else {
                        logger.error("Missing value for command line argument: " + args[i]);
                        exception = true;
                    }

                } else if (args[i].startsWith("--emailrecipient") || args[i].equals("-r")) {

                    //check if argument value present
                    if (i + 1 < args.length && !args[i + 1].startsWith("-")) {

                        for(String recipient : args[i + 1].split(",")) {
                            emailRecipients.add(recipient);
                        }
                        i++;
                    } else {
                        logger.error("Missing value for command line argument: " + args[i]);
                        exception = true;
                    }

                } else if (args[i].startsWith("--plot") || args[i].equals("-l")) {

                    plot = true;

                    //check if argument value present
                    if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        plotOutputDirectoryPath = args[i + 1];
                        i++;
                    } else {
                        plotOutputDirectoryPath = System.getProperty("user.dir");
                    }

                } else if (args[i].startsWith("--plotformat") || args[i].equals("-f")) {

                    if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
                        try {
                            plotFormat = FileFormat.valueOf(args[i]);
                        } catch(IllegalArgumentException e){
                            logger.warn("Illegal value for command line argument: " + args[i] + ". Format set to default (PDF).");
                            plotFormat = FileFormat.PDF;

                        }
                        i++;
                    } else {
                        logger.warn("Missing value for command line argument: " + args[i] + ". Format set to default (PDF).");
                    }

                } else {
                    logger.error("Illegal command line argument: " + args[i]);
                    exception = true;
                }


            }


        } catch (Exception e) {
            logger.error("Exception while reading command line arguments.", e);
            exception = true;
        }


        if (jsonConfigPath == null) {
            logger.error("Missing command line argument JSON configuration (-c).");
            exception = true;
        } else {

            if (!new File(jsonConfigPath).exists()) {
                logger.error("JSON configuration file does not exist: " + jsonConfigPath);
                exception = true;
            }

        }

        //assert required arguments are present
        if (!print && !update && !plot) {
            logger.error("At least one output command line argument (-p -u -l) required.");
            exception = true;
        }

        if (plotOutputDirectoryPath != null && !new File(plotOutputDirectoryPath).exists()) {
            logger.error("Plot output path does not exist: " + jsonConfigPath);
            exception = true;
        }

        if (plotOutputDirectoryPath != null && new File(plotOutputDirectoryPath).exists() && !new File(plotOutputDirectoryPath).isDirectory()) {
            logger.error("Plot output path is not a directory: " + plotOutputDirectoryPath);
            exception = true;
        }

        Configuration configuration = Configuration.getInstance();

        EmailAccount emailAccount = null;
        if (email && emailAccountName == null) {

            logger.error("Missing value for command line argument email account name (-e).");
            exception = true;

        } else {

            for (EmailAccount account : configuration.getEmailServers()) {
                if (account.getName().equals(emailAccountName)) {
                    emailAccount = account;
                }
            }

        }

        if(email && emailRecipients.size() == 0){

            logger.error("Missing value for command line argument email recipient (-r) missing.");
            exception = true;

        }

//        //get password from command line
//        //if not supplied as argument
//        if (password == null) {
//
//            try {
//
//                // creates a console object
//                Console cnsl = System.console();
//
//                // if console is not null
//                if (cnsl != null) {
//
//                    // read password into the char array
//                    password = cnsl.readPassword("Password: ");
//
//                }
//
//            } catch (Exception e) {
//                logger.error("Exception while reading password: " + e.getMessage());
//                exception = true;
//            }
//
//        }


//        System.out.println("jsonConfigPath = " + jsonConfigPath);
//        System.out.println("print = " + print);
//        System.out.println("email = " + email);
//        System.out.println("emailAccountName = " + emailAccountName);
//        System.out.println("Set<String> emailRecipients = " + emailRecipients);
//        System.out.println("printOutputFilePath = " + printOutputFilePath);
//        System.out.println("update = " + update);
//        System.out.println("plot = " + plot);
//        System.out.println("plotOutputDirectoryPath = " + plotOutputDirectoryPath);
//        System.out.println("plotFormat = " + plotFormat);
//        System.out.println("exception = " + exception);


        if (exception) {
            System.out.println(IgfDataManagement.usage);
            System.out.println(usage);
            System.out.println(Arrays.toString(args));
            System.exit(1);
        }


//        StorageResource cx1 = null;
//        StorageResource ax3 = null;
//        StorageResource seq = null;
//
//        try {
//
//            cx1 = new StorageResourceImpl("cx1-groupvol",
//                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/groupvol/cgi"));
//
//            seq = new StorageResourceImpl("cx1-project",
//                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/project/tgu"));
//            ax3 = new StorageResourceImpl("ax3-cgi",
//                    new URL("ftp://ax3.hpc.ic.ac.uk:/ax3-cgi"));
//
//        } catch (MalformedURLException e) {
//            logger.error("While setting up storage resource usage retriever.", e);
//        }

        //create storage resource usage retriever
        StorageResourceUsageRetriever retriever = new SshStorageResourceUsageRetriever(configuration.getSshCredentials().getUserName(),
                configuration.getSshCredentials().getPassword());

        //print
        if (print) {

            logger.info("Writing storage usage statistics to " + printOutputFilePath);
            StorageResourceUsageWriter writer = null;
            if (printOutputFilePath.equals("stdout")) {
                writer = new StorageResourceUsagePrintWriter(retriever);
            } else {
                writer = new StorageResourceUsagePrintWriter(new File(printOutputFilePath), retriever);
            }

            Object[] storageResourceArray = configuration.getStorageResources().toArray();
            writer.write(Arrays.copyOf(storageResourceArray, storageResourceArray.length, StorageResource[].class));
            logger.info("done");

        }

        //email
        if (email) {

            Object[] recipients = emailRecipients.toArray();
            logger.info("Sending storage usage statistics to " + emailRecipients.toString());
            StorageResourceUsageWriter writer = new StorageResourceUsageEmailWriter(retriever,
                    emailAccount.getSmtpHost(),
                    emailAccount.getUserName(),
                    emailAccount.getPassword(),
                    emailAccount.getSender(),
                    Arrays.copyOf(recipients, recipients.length, String[].class));

            Object[] storageResourceArray = configuration.getStorageResources().toArray();
            writer.write(Arrays.copyOf(storageResourceArray, storageResourceArray.length, StorageResource[].class));
            logger.info("done");

        }

        //update database
        if (update) {

        }

        //generate plots
        if (plot) {


        }


    }

    /**
     * @param args
     */
    public static void main(String args[]) {
        new GetStorageStats().run(args);
    }

}
