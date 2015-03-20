package uk.ac.ic.igf.datamanagement;

import uk.ac.ic.igf.datamanagement.impl.EmailAccountImpl;
import uk.ac.ic.igf.datamanagement.impl.SshCredentialsImpl;
import uk.ac.ic.igf.datamanagement.storage.StorageResource;
import uk.ac.ic.igf.datamanagement.storage.impl.StorageResourceImpl;

import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

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
 * Date: 03/11/14
 * Time: 16:19
 */
public class Configuration  {

    private JsonObject rootObject;

    /**
     * the singleton instance
     */
    private static Configuration ourInstance;

    /**
     * Get the configuration instance.
     *
     * @return the configuration singleton instance
     */
    public static Configuration getInstance(String pathToConfigJson) {

        //create the singleton instance if it doesn't exist yet
        if (ourInstance == null) {

            try {

                ourInstance = new Configuration(pathToConfigJson);

            } catch (FileNotFoundException e) {
                throw new RuntimeException(e);
            }

        }

        return ourInstance;

    }

    /**
     * Constructs the singleton instance providing access to the properties
     * in the specified properties file.
     *
     * @param jsonFile the JSON file
     */
    private Configuration(String jsonFile) throws FileNotFoundException {

        InputStream is = new FileInputStream(jsonFile);

        JsonReader rdr = Json.createReader(is);

        this.rootObject = rdr.readObject();



    }

    public SshCredentials getSshCredentials(){

        SshCredentials retVal = new SshCredentialsImpl();

        JsonObject sshCredentials = rootObject.getJsonObject("sshCredentials");

        String username = sshCredentials.getString("username");
        String password = sshCredentials.getString("password");

        retVal.setUserName(username);
        retVal.setPassword(password.toCharArray());

        return retVal;

    }

    public List<EmailAccount> getEmailServers(){

        List<EmailAccount> retVal = new ArrayList<>();

        JsonArray results = rootObject.getJsonArray("emailAccount");

        for (JsonObject result : results.getValuesAs(JsonObject.class)) {

            String name = result.getString("name");
            String smtpHost = result.getString("smtpHost");
            String username = result.getString("username");
            String password = result.getString("password");
            String sender = result.getString("sender");

            EmailAccount server = new EmailAccountImpl(name);
            server.setSmtpHost(smtpHost);
            server.setUserName(username);
            server.setPassword(password.toCharArray());
            server.setSender(sender);

            retVal.add(server);

        }

        return retVal;

    }

    public List<StorageResource> getStorageResources(){

        List<StorageResource> retVal = new ArrayList<>();

        JsonArray results = rootObject.getJsonArray("storageResource");

        for (JsonObject result : results.getValuesAs(JsonObject.class)) {

            String name = result.getString("name");
            String urlString = result.getString("url");
            URL url = null;
            try {
                url = new URL("ftp://" + urlString);
            } catch (MalformedURLException e) {
                e.printStackTrace();
            }

            StorageResource resource = new StorageResourceImpl(name, url);
            retVal.add(resource);

        }

        return retVal;

    }

    public static void main(String[] args) {

        Configuration conf = Configuration.getInstance("/home/mmuelle1/git/data-management/java/igf-data-management/src/main/resources/config/igf-data-management.json");


        for(StorageResource rsrc : conf.getStorageResources()){
            System.out.println(rsrc);
        }

        for(EmailAccount server : conf.getEmailServers()){
            System.out.println(server);
        }

    }



}
