package uk.ac.ic.igf.datamanagement.storage.impl;

import com.jcraft.jsch.*;

import uk.ac.ic.igf.datamanagement.storage.*;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
;
import java.net.URL;
import java.util.*;

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
 * Time: 18:08
 */
public class SshStorageResourceUsageRetriever implements StorageResourceUsageRetriever {

    /**
     * the log4j logger
     */
    private static org.apache.log4j.Logger logger = org.apache.log4j.Logger.getLogger(SshStorageResourceUsageRetriever.class);

    private String username;
    private char[] password;

    private Map<String, StorageResourceUsage> storageResourceUsageCache = new TreeMap<>();

    public SshStorageResourceUsageRetriever(String username, char[] password) {

        this.username = username;
        this.password = password;

    }

    /**
     * Returns the storage resource usage for all registered resources.
     *
     * @param storageResource
     * @return list of storage resource usage objects
     */
    @Override
    public List<StorageResourceUsage> retrieveUsage(StorageResource... storageResource) {

        List<StorageResourceUsage> retval = new ArrayList<>();

        for(StorageResource resource : storageResource){

            retval.add(this.retrieveUsage(resource));

        }

        return retval;

    }

    /**
     * Returns the storage usage for a specific resource.
     *
     * @param storageResource
     * @return the storage resource usage
     */
    @Override
    public StorageResourceUsage retrieveUsage(StorageResource storageResource) {

        if(!this.storageResourceUsageCache.containsKey(storageResource.getResourceName())){

            storageResourceUsageCache.put(storageResource.getResourceName(), new SshStorageResourceUsage(storageResource, username, password));

        }

        return storageResourceUsageCache.get(storageResource.getResourceName());

    }



    public static void main(String[] args) {

        try {

            StorageResource cx1 = new StorageResourceImpl("cx1",
                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/groupvol/cgi"));
            StorageResource seq = new StorageResourceImpl("seq",
                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/project/tgu"));
            StorageResource ax3 = new StorageResourceImpl("ax3",
                    new URL("ftp://ax3.hpc.ic.ac.uk:/ax3-cgi"));

            StorageResourceUsageRetriever retriever = new SshStorageResourceUsageRetriever(
                    "mmuelle1",
                    new String("*2008/cA").toCharArray());



        } catch (IOException e) {
            System.out.println(e);
        }

    }


}
