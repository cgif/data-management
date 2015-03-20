package uk.ac.ic.igf.datamanagement.storage.impl;

import com.jcraft.jsch.*;
import uk.ac.ic.igf.datamanagement.storage.DataCategory;
import uk.ac.ic.igf.datamanagement.storage.StorageResource;
import uk.ac.ic.igf.datamanagement.storage.StorageResourceUsage;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
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
 * Date: 08/10/14
 * Time: 16:29
 */
public class SshStorageResourceUsage implements StorageResourceUsage {

    private StorageResource storageResource;

    private String username;
    private char[] password;
    private Session sshSession;

    private long usedDiskSpace = -1;
    private long totalDiskSpace = -1;
    private Map<DataCategory, Map<String, Map<String, Long>>> usageByCategoryProjectWorkflow = new TreeMap<>();

    private boolean categoriesInitialised = false;
    private boolean projectsInitialised = false;
    private boolean workflowsInitialised = false;

    /**
     * the log4j logger
     */
    private static org.apache.log4j.Logger logger = org.apache.log4j.Logger.getLogger(SshStorageResourceUsage.class);


    public SshStorageResourceUsage(StorageResource storageResource, String username, char[] password) {

        this.storageResource = storageResource;
        this.username = username;
        this.password = password;
        this.sshSession = initialiseSshSession();
        this.initialiseCategories();

    }

    private Session initialiseSshSession() {

        Session retval = null;

        String host = storageResource.getResourceUrl().getHost();

        try {

            Properties config = new Properties();
            config.put("StrictHostKeyChecking", "no");
            JSch jsch = new JSch();
            retval = jsch.getSession(username, host, 22);
            retval.setPassword(new String(password));
            retval.setConfig(config);
            retval.connect();

        } catch (Exception e) {
            logger.error("Exception while initialising SSH session. ", e);
        }

        return retval;

    }

    private void closeSshSession() {
        this.sshSession.disconnect();
    }

    /**
     * Returns the storage resource.
     *
     * @return the storage resource.
     */
    @Override
    public StorageResource getStorageResource() {
        return storageResource;
    }

    /**
     * Sets the storage resource.
     *
     * @param storageResource the storage resource
     */
    @Override
    public void setStorageResource(StorageResource storageResource) {
        this.storageResource = storageResource;
    }

    /**
     * Returns the available disk space in kilobytes
     *
     * @return the disk space in kilobytes
     */
    @Override
    public long getUsedDiskSpace() {

        if (usedDiskSpace == -1) {

            this.fetchResourceDiskSpaceInfo();

        }

        return usedDiskSpace;

    }

    /**
     * Sets the available disk space in kilobytes.
     *
     * @param diskSpace the disk space in kilobytes
     */
    @Override
    public void setUsedDiskSpace(long diskSpace) {
        this.usedDiskSpace = diskSpace;
    }

    /**
     * Returns the total disk space in kilobytes
     *
     * @return total available disk space
     */
    @Override
    public long getTotalDiskSpace() {

        if (totalDiskSpace == -1) {

            this.fetchResourceDiskSpaceInfo();

        }

        return totalDiskSpace;

    }

    /**
     * Sets the total disk space.
     *
     * @param diskSpace disk space in kilobytes
     */
    @Override
    public void setTotalDiskSpace(long diskSpace) {
        this.totalDiskSpace = diskSpace;
    }

    /**
     * Returns the total data storage usage in kilobytes for the specified
     * data category.
     *
     * @param category
     * @return storage usage in kb
     */
    @Override
    public long getUsage(DataCategory category) {

        long retval = 0;

        if(!workflowsInitialised){
            this.initialiseWorkflows();
        }

        if (category == DataCategory.OTHER) {

            retval = this.getUsedDiskSpace();

            for (DataCategory cat : DataCategory.values()) {

                if (cat != DataCategory.OTHER) {

                    logger.debug("cat = " + cat + ", retval = " + retval);
                    retval = retval - this.getUsage(cat);

                }

            }

            //return retval;

        } else if (this.usageByCategoryProjectWorkflow.containsKey(category)) {

            retval = 0;

            for (String projectTag : this.usageByCategoryProjectWorkflow.get(category).keySet()) {

                for (String workflow : this.usageByCategoryProjectWorkflow.get(category).get(projectTag).keySet()) {

                    long usage = this.getUsage(category, projectTag, workflow);

                    retval = retval + usage;

                }

            }

        }

        return retval;

    }

    /**
     * Sets the storage usage for a data category, project and workflow.
     *
     * @param category   the data category
     * @param projectTag the project tag
     * @param workflow   the workflow
     * @param usage      the usage in kilobytes
     */
    @Override
    public void setUsage(DataCategory category, String projectTag, String workflow, long usage) {

        if (!this.usageByCategoryProjectWorkflow.containsKey(category)) {
            this.usageByCategoryProjectWorkflow.put(category, new TreeMap<String, Map<String, Long>>());
        }

        if (!this.usageByCategoryProjectWorkflow.get(category).containsKey(projectTag)) {
            this.usageByCategoryProjectWorkflow.get(category).put(projectTag, new TreeMap<String, Long>());
        }

        this.usageByCategoryProjectWorkflow.get(category).get(projectTag).put(workflow, usage);

    }


    public long getUsage(DataCategory category, String projectTag, String workflow) {

        if(!workflowsInitialised){
            this.initialiseWorkflows();
        }

        long retval = -1;

        if (!(this.usageByCategoryProjectWorkflow.containsKey(category)
                && this.usageByCategoryProjectWorkflow.get(category).containsKey(projectTag)
                && this.usageByCategoryProjectWorkflow.get(category).get(projectTag).containsKey(workflow))) {

            retval = 0;
            //logger.warn("Workflow " + workflow + " for project " + projectTag + " in category " + category + " not present on resource " + storageResource.getResourceName() + ".");

        } else if (this.usageByCategoryProjectWorkflow.get(category).get(projectTag).get(workflow) == -1) {

            this.fetchUsage(category, projectTag, workflow);
            retval = this.usageByCategoryProjectWorkflow.get(category).get(projectTag).get(workflow);

        } else {

            retval = this.usageByCategoryProjectWorkflow.get(category).get(projectTag).get(workflow);

        }

        return retval;

    }

    /**
     * Returns the total data storage usage in kilobytes for the specified
     * project.
     *
     * @param projectTag the project tag
     * @return storage usage in kb
     */
    @Override
    public long getUsageByProject(String projectTag) {

        long retval = 0;

        if(!workflowsInitialised){
            this.initialiseWorkflows();
        }

        for (DataCategory category : this.usageByCategoryProjectWorkflow.keySet()) {

            if (this.usageByCategoryProjectWorkflow.get(category).containsKey(projectTag)) {

               for (String workflow : this.usageByCategoryProjectWorkflow.get(category).get(projectTag).keySet()) {

                   long usage = this.getUsage(category, projectTag, workflow);

                   retval = retval + usage;

               }

            }

        }

        return retval;

    }

    /**
     * Returns the storage usage in kilobytes for the specified
     * project and data category.
     *
     * @param projectTag the project tag
     * @param category
     * @return storage usage in kb
     */
    @Override
    public long getUsageByProject(String projectTag, DataCategory category) {

        if(!workflowsInitialised){
            this.initialiseWorkflows();
        }

        long retval = 0;

        //logger.debug(projectTag + "," +  category);

        if (this.usageByCategoryProjectWorkflow.containsKey(category) && this.usageByCategoryProjectWorkflow.get(category).containsKey(projectTag)) {

            logger.debug(projectTag + "," +  category);
            logger.debug(this.usageByCategoryProjectWorkflow.get(category).get(projectTag).size());

            for (String workflow : this.usageByCategoryProjectWorkflow.get(category).get(projectTag).keySet()) {

                logger.debug("this.getUsage(" + category + "," + projectTag + "," + workflow + ")");
                long usage = this.getUsage(category, projectTag, workflow);

                retval = retval + usage;

            }

        }

        return retval;

    }

    /**
     * Returns the total storage usage in kilobytes for the specified
     * workflow.
     *
     * @param workflowName the name of the workflow
     * @return storage usage in kb
     */
    @Override
    public long getUsageByWorkflow(String workflowName) {

        long retval = 0;

        if(!workflowsInitialised){
            initialiseWorkflows();
        }

        for (DataCategory category : this.usageByCategoryProjectWorkflow.keySet()) {

            retval = retval + this.getUsageByWorkflow(workflowName, category);

        }

        return retval;


    }

    /**
     * Returns the storage usage in kilobytes for the specified
     * workflow and data category.
     *
     * @param workflowName the name of the workflow
     * @param category     the data category
     * @return storage usage in kb
     */
    @Override
    public long getUsageByWorkflow(String workflowName, DataCategory category) {

        long retval = 0;

        if(!workflowsInitialised){
            initialiseWorkflows();
        }

        if (!this.usageByCategoryProjectWorkflow.containsKey(category)) {

            for (String projectTag : this.usageByCategoryProjectWorkflow.get(category).keySet()) {

                long usage = this.getUsage(category, projectTag, workflowName);

                retval = retval + usage;

            }

        }

        return retval;

    }

    /**
     * Returns a set of project tags of projects for which data is stored on the storage resource.
     *
     * @return set of project tags
     */
    @Override
    public Set<String> getProjectTags() {

        if(!projectsInitialised){
            this.initialiseProjects();
        }

        Set<String> retval = new TreeSet<>();

        for (DataCategory category : this.usageByCategoryProjectWorkflow.keySet()) {

            for (String projectTag : this.usageByCategoryProjectWorkflow.get(category).keySet()) {

                if (!projectTag.equals("NA")) {
                    retval.add(projectTag);
                }

            }

        }

        return retval;

    }

    /**
     * Returns a set of workflow names for which data is stored on the storage resource.
     *
     * @return set of workflow names
     */
    @Override
    public Set<String> getWorkflowNames() {

        logger.debug("getWorkflowNames()");

        if(!workflowsInitialised){
            this.initialiseWorkflows();
        }

        logger.debug("getWorkflowNames()");

        Set<String> retval = new TreeSet<>();

        for (DataCategory category : this.usageByCategoryProjectWorkflow.keySet()) {

            for (String projectTag : this.usageByCategoryProjectWorkflow.get(category).keySet()) {

                for (String workflow : this.usageByCategoryProjectWorkflow.get(category).get(projectTag).keySet()) {

                    if (!workflow.equals("NA")) {

                        retval.add(workflow);

                    }

                }

            }

        }

        return retval;

    }

    @Override
    public Set<String> getWorkflowNames(String projectTag) {

        if(!workflowsInitialised){
            initialiseWorkflows();
        }

        Set<String> retval = new TreeSet<>();

        for (DataCategory category : this.usageByCategoryProjectWorkflow.keySet()) {

            if (this.usageByCategoryProjectWorkflow.get(category).containsKey(projectTag)) {

                for (String workflow : this.usageByCategoryProjectWorkflow.get(category).get(projectTag).keySet()) {

                    if (!workflow.equals("NA")) {

                        retval.add(workflow);

                    }

                }

            }

        }

        return retval;

    }


    private void fetchResourceDiskSpaceInfo() {

        try {

            Channel channel = sshSession.openChannel("exec");
            String diskFree = "df " + storageResource.getResourceUrl().getPath();

            logger.debug(diskFree);

            ((ChannelExec) channel).setCommand(diskFree);
            channel.setInputStream(null);
            ((ChannelExec) channel).setErrStream(System.err);

            InputStream in = channel.getInputStream();
            channel.connect();

            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));

            long totalDiskSpace = -1;
            long used = -1;

            String line = "";
            List<String> lines = new ArrayList<>();

            while ((line = bufferedReader.readLine()) != null) {

                lines.add(line);

            }

            bufferedReader.close();
            in.close();

            channel.disconnect();

            logger.debug("lines.size() = " + lines.size());

            //If the path of the resource is long
            //the second line of the df output can be
            //wrapped. To get the parsing right we need
            //to check how many lines are returned.
            //
            //If only two the second line has not been
            //wrapped and the information we want is in
            //the second line...
            if (lines.size() == 2) {

                line = lines.get(1);
                StringTokenizer tokenizer = new StringTokenizer(line, " ");

                if (tokenizer.countTokens() > 0) {

                    //skip the resource path
                    tokenizer.nextToken();

                    //read size
                    totalDiskSpace = Long.parseLong(tokenizer.nextToken());

                    //read used
                    used = Long.parseLong(tokenizer.nextToken());

                }

                //...if three the second line has been wrapped
                //and the information we want is in the third line.
            } else if (lines.size() == 3) {

                line = lines.get(2);

                StringTokenizer tokenizer = new StringTokenizer(line, " ");

                if (tokenizer.countTokens() > 0) {

                    //read size
                    totalDiskSpace = Long.parseLong(tokenizer.nextToken());

                    //read used
                    used = Long.parseLong(tokenizer.nextToken());

                }

            }

            logger.debug("Total disk space for resource " + storageResource.getResourceName() + " equals " + totalDiskSpace);

            this.setTotalDiskSpace(totalDiskSpace);
            this.setUsedDiskSpace(used);

        } catch (IOException | JSchException e) {
            logger.warn("Exception while retrieving total disk space information from resource " + storageResource.getResourceName() + ".", e);
        }

    }

    private void initialiseCategories(){

        logger.debug("initialiseCategories()");

        for (DataCategory category : DataCategory.values()) {

            this.usageByCategoryProjectWorkflow.put(category, new TreeMap<String, Map<String, Long>>());

        }

        categoriesInitialised=true;

    }


    private void initialiseProjects() {

        logger.debug("initialiseProjects()");

        if(!categoriesInitialised){
            initialiseCategories();
        }

        //fetch projects
        for (DataCategory category : usageByCategoryProjectWorkflow.keySet()) {

                if (category == DataCategory.RAWDATA ||
                        category == DataCategory.ANALYSIS ||
                        category == DataCategory.RESULTS ||
                        category == DataCategory.RUNS) {

                    try {

                    //fetch project directories in category
                    Channel channel = sshSession.openChannel("exec");

                    String path = storageResource.getResourceUrl().getPath() + "/" + category.getDirectoryName();

                    String command = "for ENTRY in `ls -1 --color=never " + path + "`; do if [ -d \"" + path + "/$ENTRY\" ]; then echo $ENTRY; fi; done";

                    logger.debug(command);

                    ((ChannelExec) channel).setCommand(command);
                    channel.setInputStream(null);
                    ((ChannelExec) channel).setErrStream(System.err);

                    InputStream in = channel.getInputStream();
                    channel.connect();

                    BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));

                    String projectTag = "";
                    while ((projectTag = bufferedReader.readLine()) != null) {

                        usageByCategoryProjectWorkflow.get(category).put(projectTag, new TreeMap<String, Long>());

                        if(category == DataCategory.RAWDATA){

                            String workflow = "NA";
                            usageByCategoryProjectWorkflow.get(category).get(projectTag).put(workflow , (long) -1);

                        }

                    }

                    bufferedReader.close();
                    in.close();

                    channel.disconnect();

                    } catch (IOException | JSchException e) {
                        logger.warn("Exception while initialising usage cache: " + category + " from resource " + storageResource.getResourceName() + ".", e);
                    }

                } else {

                    String projectTag = "NA";
                    String workflow = "NA";

                    usageByCategoryProjectWorkflow.get(category).put(projectTag, new TreeMap<String, Long>());
                    usageByCategoryProjectWorkflow.get(category).get(projectTag).put(workflow , (long) -1);

                }

        }

        projectsInitialised=true;
        logger.debug("projectsInitialised=true");

    }

    private void initialiseWorkflows(){

        logger.debug("initialiseWorkflows()");

        if(!projectsInitialised){
            initialiseProjects();
        }

        //fetch projects
        for (DataCategory category : usageByCategoryProjectWorkflow.keySet()) {

            logger.debug(category);

            if (category == DataCategory.ANALYSIS ||
                    category == DataCategory.RESULTS) {

                //fetch workflows
                for (String projectTag : usageByCategoryProjectWorkflow.get(category).keySet()) {

                    try{

                        Channel channel = sshSession.openChannel("exec");

                        String path = storageResource.getResourceUrl().getPath() + "/" + category.getDirectoryName() + "/" + projectTag;

                        String command = "for ENTRY in `ls -1 --color=never " + path + "`; do if [ -d \"" + path + "/$ENTRY\" ]; then echo $ENTRY; fi; done";

                        //logger.debug(command);

                        ((ChannelExec) channel).setCommand(command);
                        channel.setInputStream(null);
                        ((ChannelExec) channel).setErrStream(System.err);

                        InputStream in = channel.getInputStream();
                        channel.connect();

                        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));

                        String workflow = "";
                        while ((workflow = bufferedReader.readLine()) != null) {

                            usageByCategoryProjectWorkflow.get(category).get(projectTag).put(workflow, (long) -1);

                        }

                        bufferedReader.close();
                        in.close();

                        channel.disconnect();

                    } catch (IOException | JSchException e) {
                        logger.warn("Exception while initialising usage cache: " + category + " from resource " + storageResource.getResourceName() + ".", e);
                    }

                }

            }

        }

        workflowsInitialised=true;

    }

    private void fetchUsage(DataCategory category, String projectTag, String workflow) {

        try {

            Channel channel = sshSession.openChannel("exec");

            String resourcePath = storageResource.getResourceUrl().getPath();

            String command = "du -s " + resourcePath + "/" + category.getDirectoryName();

            //append project tag
            if (!projectTag.equals("NA")) {

                command = command + "/" + projectTag;

            }

            //append workflow
            if(!workflow.equals("NA")){

                command = command + "/" + workflow;

            }

            logger.debug(command);

            ((ChannelExec) channel).setCommand(command);
            channel.setInputStream(null);
            ((ChannelExec) channel).setErrStream(System.err);

            InputStream in = channel.getInputStream();
            channel.connect();

            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));

            String line = bufferedReader.readLine();

            if (line != null) {

                if (!line.contains("No such file or directory")) {

                    StringTokenizer tokenizer = new StringTokenizer(line, "\t");

                    String usageString = "";
                    String path = "";
                    if (tokenizer.countTokens() > 0) {
                        usageString = tokenizer.nextToken();
                        path = tokenizer.nextToken();
                    }

                    long usage = 0;
                    try {
                        usage = Long.parseLong(usageString);
                    } catch (NumberFormatException e) {
                        logger.warn("Exception while parsing storage usage from input string " + line + ".", e);
                    }

                    //replace path prefix
                    path = path.replaceFirst(resourcePath + "/", "");

                    tokenizer = new StringTokenizer(path, "/");

                    //skip category
                    tokenizer.nextToken();

                    //get project tag
//                    String projectTag = "NA";
//                    if (category == DataCategory.RAWDATA || category == DataCategory.ANALYSIS || category == DataCategory.RESULTS) {
//                        projectTag = tokenizer.nextToken();
//                    }

//                    String workflow = "NA";
//                    if (category == DataCategory.ANALYSIS || category == DataCategory.RESULTS) {
//                        //get workflow name
//                        workflow = tokenizer.nextToken();
//                    }

                    logger.debug(category + "\t" + projectTag + "\t" + workflow + "\t" + usage);

                    this.usageByCategoryProjectWorkflow.get(category).get(projectTag).put(workflow, usage);

                } else {
                    logger.warn("Exception while fetching resource usage: " + line);
                }

            }

            bufferedReader.close();
            in.close();

            channel.disconnect();

        } catch (IOException | JSchException e) {
            logger.warn("Exception while retrieving storage usage for category " + category + " from resource " + storageResource.getResourceName() + ".", e);
        }

    }

    protected void finalize() throws Throwable {
        // Invoke the finalizer of our superclass
        // We haven't discussed superclasses or this syntax yet
        super.finalize();

        // Close SSH session
        this.closeSshSession();
    }

}
