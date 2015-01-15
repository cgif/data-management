package uk.ac.ic.igf.datamanagement.storage.impl;

import uk.ac.ic.igf.datamanagement.storage.StorageResource;
import uk.ac.ic.igf.datamanagement.storage.StorageResourceUsageRetriever;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.MimeMessage;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Date;
import java.util.HashSet;
import java.util.Properties;
import java.util.Set;

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
 * Date: 29/10/14
 * Time: 15:40
 */
public class StorageResourceUsageEmailWriter extends StorageResourceUsagePrintWriter {

    /**
     * the log4j logger
     */
    private static org.apache.log4j.Logger logger = org.apache.log4j.Logger.getLogger(SshStorageResourceUsageRetriever.class);

    private String username;
    private char[] password;
    private String fromEmailAddress;
    public String smtpMailServer;
    private String toEmailAddresses;

    public StorageResourceUsageEmailWriter(StorageResourceUsageRetriever retriever, String smtpMailServer, String username, char[] password, String fromEmailAddress, String... toEmailAddresses){
        super(retriever);
        this.smtpMailServer=smtpMailServer;
        this.username=username;
        this.password=password;
        this.fromEmailAddress=fromEmailAddress;
        this.toEmailAddresses=makeToEmailAdressString(toEmailAddresses);
    }

    private String makeToEmailAdressString(String... addresses){

        StringBuffer sb = new StringBuffer();
        int count = 0;
        for(String address : addresses){
            count++;
            sb.append(address);
            if(count != addresses.length) {
                sb.append(",");
            }
        }

        return sb.toString();

    }

    public void write(StorageResource... resources) {

        Properties props = new Properties();
        props.put("mail.smtp.host", smtpMailServer);
        Session session = Session.getInstance(props, null);

        StringWriter writer = new StringWriter();
        PrintWriter printWriter = new PrintWriter(writer);

        super.writeUsageByResource(printWriter, resources);
        super.writeUsageByProject(printWriter, resources);
        super.writeUsageByWorkflow(printWriter, resources);

        String subject = "IGF Storage Usage Statistics " + new Date().toString();
        String message = subject + "\n\n" + writer.toString();

        try {

            MimeMessage msg = new MimeMessage(session);
            msg.setFrom(fromEmailAddress);

            msg.setRecipients(Message.RecipientType.TO,
                    toEmailAddresses);

            msg.setSubject(subject);
            msg.setSentDate(new Date());
            msg.setText(message);

            Transport.send(msg, username, new String(password));

        } catch (MessagingException mex) {
            logger.error("Send failed.", mex);
        }

    }

    public static void main(String[] args) {

        try {

            StorageResourceUsageRetriever retriever = new SshStorageResourceUsageRetriever(
                    "mmuelle1",
                    "*2008/cAm".toCharArray());

            StorageResource cx1 = new StorageResourceImpl("cx1",
                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/groupvol/cgi"));

            StorageResourceUsageEmailWriter writer = new StorageResourceUsageEmailWriter(retriever, "exchange.imperial.ac.uk", "cgi", "teSSel14g".toCharArray(), "cgi@ic.ac.uk","mmuelle1@ic.ac.uk");

            writer.write(cx1);

        } catch (MalformedURLException e) {
            e.printStackTrace();
        }

    }

}
