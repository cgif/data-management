package uk.ac.ic.igf.datamanagement.storage.impl;

import uk.ac.ic.igf.datamanagement.storage.*;

import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;
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
 * Date: 24/09/14
 * Time: 14:26
 */
public class StorageResourceUsagePrintWriter implements StorageResourceUsageWriter {

    /**
     * the log4j logger
     */
    private static org.apache.log4j.Logger logger = org.apache.log4j.Logger.getLogger(SshStorageResourceUsageRetriever.class);

    private String outputPath;
    private StorageResourceUsageRetriever retriever;


    public StorageResourceUsagePrintWriter(File file, StorageResourceUsageRetriever retriever) {

        this.outputPath = file.getAbsolutePath();
        this.retriever=retriever;

    }

    public StorageResourceUsagePrintWriter(StorageResourceUsageRetriever retriever) {

        this.outputPath = "STDN";
        this.retriever=retriever;

    }

    @Override
    public void write(StorageResource... resources)
    {

        PrintWriter printWriter;

        if (outputPath.equals("STDN")) {
            printWriter = new PrintWriter(System.out);
        } else {
            try {
                printWriter = new PrintWriter(new FileWriter(outputPath));
            } catch (IOException e) {
                logger.error("Error while writing storage stats to file " + outputPath + ".", e);
                return;
            }
        }

        writeUsageByResource(printWriter, resources);

        writeUsageByProject(printWriter, resources);

        writeUsageByWorkflow(printWriter, resources);

        printWriter.close();

    }


    protected void writeUsageByResource(PrintWriter printWriter, StorageResource... resources){

        long denominator = 1024;

        float totalUsageRawDataGb = 0;
        float totalUsageAnalysisGb = 0;
        float totalUsageResultsGb = 0;
        float totalUsageRunsGb = 0;
        float totalUsageSrcGb = 0;
        float totalUsageResourcesGb = 0;
        float totalUsageOtherGb = 0;
        float totalRowTotal = 0;
        float totalSpaceTotal = 0;
        float usedPercent = 0;

        printWriter.println("USAGE BY RESOURCE");
        printWriter.println("=================");
        printWriter.println("");
        printWriter.println("-------------------------------------------------------------------------------------------------------------------------");
        printWriter.printf("%-8s %10s %10s %10s %10s %10s %10s %10s %10s | %11s %10s\n", "resource", DataCategory.RAWDATA.getDirectoryName(), DataCategory.ANALYSIS.getDirectoryName(), DataCategory.RESULTS.getDirectoryName(), DataCategory.RUNS.getDirectoryName(), DataCategory.RESOURCES.getDirectoryName(), DataCategory.SRC.getDirectoryName(), DataCategory.OTHER.getDirectoryName(), "row total", "total space", "used");
        printWriter.printf("%-8s %10s %10s %10s %10s %10s %10s %10s %10s | %11s %10s\n", "", "[GB]", "[GB]", "[GB]", "[GB]", "[GB]", "[GB]", "[GB]", "[GB]", "[GB]", "[%]");
        printWriter.println("-------------------------------------------------------------------------------------------------------------------------");

        for (StorageResourceUsage usage : retriever.retrieveUsage(resources)) {

            String resourceName = usage.getStorageResource().getResourceName();

            float usageRawDataGb = (float) (usage.getUsage(DataCategory.RAWDATA) / denominator) / denominator;
            totalUsageRawDataGb = totalUsageRawDataGb + usageRawDataGb;

            float usageAnalysisGb = (float) (usage.getUsage(DataCategory.ANALYSIS) / denominator) / denominator;
            totalUsageAnalysisGb = totalUsageAnalysisGb + usageAnalysisGb;

            float usageResultsGb = (float) (usage.getUsage(DataCategory.RESULTS) / denominator) / denominator;
            totalUsageResultsGb = totalUsageResultsGb + usageResultsGb;

            float usageRunsGb = (float) (usage.getUsage(DataCategory.RUNS) / denominator) / denominator;
            totalUsageRunsGb = totalUsageRunsGb + usageRunsGb;

            float usageSrcGb = (float) (usage.getUsage(DataCategory.SRC) / denominator) / denominator;
            totalUsageSrcGb = totalUsageSrcGb + usageSrcGb;

            float usageResourcesGb = (float) (usage.getUsage(DataCategory.RESOURCES) / denominator) / denominator;
            totalUsageResourcesGb = totalUsageResourcesGb + usageResourcesGb;

            float usageOtherGb = (float) (usage.getUsage(DataCategory.OTHER) / denominator) / denominator;
            totalUsageOtherGb = totalUsageOtherGb + usageOtherGb;

            float rowTotal = usageRawDataGb + usageAnalysisGb + usageResultsGb + usageRunsGb + usageSrcGb + usageResourcesGb + usageOtherGb;

            float totalSpace = (float)(usage.getTotalDiskSpace()/ denominator) / denominator;
            totalSpaceTotal = totalSpaceTotal + totalSpace;

            usedPercent = rowTotal/totalSpace*100;

            printWriter.printf("%-8s %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f | %10.1f %10.1f\n", resourceName, usageRawDataGb, usageAnalysisGb, usageResultsGb, usageRunsGb, usageResourcesGb, usageSrcGb, usageOtherGb, rowTotal, totalSpace, usedPercent);
            printWriter.flush();

        }

        totalRowTotal = totalUsageRawDataGb + totalUsageAnalysisGb + totalUsageResultsGb + totalUsageRunsGb + totalUsageSrcGb + totalUsageResourcesGb + totalUsageOtherGb;
        float usedPercentTotal = totalRowTotal/totalSpaceTotal*100;

        printWriter.println("=========================================================================================================================");

        printWriter.printf("%-8s %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f | %10.1f %10.1f\n", "total", totalUsageRawDataGb, totalUsageAnalysisGb, totalUsageResultsGb, totalUsageRunsGb, totalUsageResourcesGb, totalUsageSrcGb, totalUsageOtherGb, totalRowTotal, totalSpaceTotal, usedPercentTotal);
        printWriter.println("-------------------------------------------------------------------------------------------------------------------------");
        printWriter.println("");
        printWriter.println("");
        printWriter.flush();


    }

    protected void writeUsageByProject(PrintWriter printWriter, StorageResource... resources){

        long denominator = 1024;

        //USAGE BY RESOURCE
        printWriter.println("USAGE BY PROJECT");
        printWriter.println("================");
        printWriter.println("");
        printWriter.println("----------------------------------------------------------------------------------------------");
        printWriter.printf("%-10s %-20s %10s %10s %10s %10s %10s %7s\n", "resource", "project", DataCategory.RAWDATA.getDirectoryName(), DataCategory.ANALYSIS.getDirectoryName(), DataCategory.RESULTS.getDirectoryName(), DataCategory.RUNS.getDirectoryName(), "row total", "");
        printWriter.printf("%-10s %-20s %10s %10s %10s %10s %10s %7s\n", "", "", "[GB]", "[GB]", "[GB]", "[GB]", "[GB]", "[%]");
        printWriter.println("----------------------------------------------------------------------------------------------");

        for (StorageResourceUsage usage : retriever.retrieveUsage(resources)) {

            int row = 0;
            String resourceName = usage.getStorageResource().getResourceName();

            //calculate total usage
            float totalUsage = 0;
            for (String projectTag : usage.getProjectTags()) {

                totalUsage = totalUsage + usage.getUsageByProject(projectTag);

            }

            float totalUsageGb = (totalUsage / denominator) / denominator;

            logger.debug("totalUsage=" + totalUsage);

            for (String projectTag : usage.getProjectTags()) {

                row++;

                if (row > 1) {
                    resourceName = "";
                }

                float usageRawDataGb = (float) (usage.getUsageByProject(projectTag, DataCategory.RAWDATA) / denominator) / denominator;
                float usageAnalysisGb = (float) (usage.getUsageByProject(projectTag, DataCategory.ANALYSIS) / denominator) / denominator;
                float usageResultsGb = (float) (usage.getUsageByProject(projectTag, DataCategory.RESULTS) / denominator) / denominator;
                float usageRunsGb = (float) (usage.getUsageByProject(projectTag, DataCategory.RUNS) / denominator) / denominator;
                float rowTotal = usageRawDataGb + usageAnalysisGb + usageResultsGb + usageRunsGb;
                float usagePercent = rowTotal/totalUsageGb*100;
                logger.debug("usagePercent=" + usagePercent);

                int strln = 20;
                if (projectTag.length() < strln) {
                    strln = projectTag.length();
                }

                printWriter.printf("%-10s %-20s %10.1f %10.1f %10.1f %10.1f %10.1f (%5.1f)\n", resourceName, projectTag.substring(0, strln), usageRawDataGb, usageAnalysisGb, usageResultsGb, usageRunsGb, rowTotal, usagePercent);

            }

            printWriter.println("----------------------------------------------------------------------------------------------");
        }

        printWriter.println("");
        printWriter.println("");
        printWriter.flush();

    }

    protected void writeUsageByWorkflow(PrintWriter printWriter, StorageResource... resources){

        long denominator = 1024;

        printWriter.println("USAGE BY WORKFLOW");
        printWriter.println("=================");
        printWriter.println("");
        printWriter.println("--------------------------------------------------------------------------------------");
        printWriter.printf("%-10s %-20s %-10s %10s %10s %10s %10s \n", "resource", "project", "workflow", DataCategory.RAWDATA.getDirectoryName(), DataCategory.ANALYSIS.getDirectoryName(), DataCategory.RESULTS.getDirectoryName(), "row total");
        printWriter.printf("%-10s %-20s %-10s %10s %10s %10s %10s \n", "", "", "", "[GB]", "[GB]", "[GB]", "[GB]");
        printWriter.println("--------------------------------------------------------------------------------------");

        for (StorageResourceUsage usage : retriever.retrieveUsage(resources)) {

            int resourceRow = 0;
            String resourceName = usage.getStorageResource().getResourceName();

            Set<String> projectTags = usage.getProjectTags();
            int projectCount = projectTags.size();
            int projectCounter = 0;

            for (String projectTag : projectTags) {

//                 System.out.println(resourceName + " " + projectTag);
                int projectRow = 0;
                projectCounter++;
                int strln = 20;
                if (projectTag.length() < strln) {
                    strln = projectTag.length();
                }
                String project = projectTag.substring(0, strln);

                if (resourceRow > 1) {
                    resourceName = "";
                }

                float usageRawDataGb = 0;
                float usageAnalysisGb = 0;
                float usageResultsGb = 0;
                float rowTotal = 0;
                String workflowSubStr = "";

                for (String workflow : usage.getWorkflowNames(projectTag)) {

                    resourceRow++;
                    projectRow++;
                    if (projectRow > 1) {
                        project = "";
                    }

                    strln = 10;
                    if (workflow.length() < strln) {
                        strln = workflow.length();
                    }
                    workflowSubStr = workflow.substring(0, strln);

                    if (resourceRow > 1) {
                        resourceName = "";
                    }

                    usageRawDataGb = 0;
                    usageAnalysisGb = (float) (usage.getUsage(DataCategory.ANALYSIS, projectTag, workflow) / denominator) / denominator;
                    usageResultsGb = (float) (usage.getUsage(DataCategory.RESULTS, projectTag, workflow) / denominator) / denominator;
                    rowTotal = usageRawDataGb + usageAnalysisGb + usageResultsGb;

                    printWriter.printf("%-10s %-20s %-10s %10.1f %10.1f %10.1f %10.1f\n", resourceName, project, workflowSubStr, usageRawDataGb, usageAnalysisGb, usageResultsGb, rowTotal);
                    printWriter.flush();

                }

                resourceRow++;
                projectRow++;
                if (projectRow > 1) {
                    project = "";
                }

                if (resourceRow > 1) {
                    resourceName = "";
                }

                //print rawdata usage which does not have workflows
                usageRawDataGb = (float) (usage.getUsageByProject(projectTag, DataCategory.RAWDATA) / denominator) / denominator;
                usageAnalysisGb = 0;
                usageResultsGb = 0;
                rowTotal = usageRawDataGb + usageAnalysisGb + usageResultsGb;
                workflowSubStr = "other";

                printWriter.printf("%-10s %-20s %-10s %10.1f %10.1f %10.1f %10.1f\n", resourceName, project, workflowSubStr, usageRawDataGb, usageAnalysisGb, usageResultsGb, rowTotal);
                printWriter.flush();




                if (projectCounter != projectCount) {
                    printWriter.println("           ---------------------------------------------------------------------------");
                    printWriter.flush();
                }

            }

            printWriter.println("--------------------------------------------------------------------------------------");
            printWriter.flush();

        }

        printWriter.println("");
        printWriter.println("");
        printWriter.flush();

    }


    public static void main(String[] args) {

        try {

            StorageResource cx1 = new StorageResourceImpl("cx1",
                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/groupvol/cgi"));
            StorageResource seq = new StorageResourceImpl("seq",
                    new URL("ftp://login.cx1.hpc.ic.ac.uk:/project/tgu"));
            StorageResource ax3 = new StorageResourceImpl("ax3",
                    new URL("ftp://ax3.hpc.ic.ac.uk:/ax3-cgi"));

//            cx1.setTotalDiskSpace(27000000000l);
//            cx1.setTotalDiskSpace(27000000000l);
//
//            ax3.setTotalDiskSpace(27000000000l);
//            ax3.setTotalDiskSpace(27000000000l);

            StorageResourceUsageRetriever retriever = new SshStorageResourceUsageRetriever(
                    "mmuelle1",
                    new String("*2008/cAm").toCharArray());
//                      cx1);
//


//            StorageResourceUsage usageCx1 = new StorageResourceUsageImpl(cx1);
//            StorageResourceUsage usageAx3 = new StorageResourceUsageImpl(ax3);
//
//            usageCx1.setUsedDiskSpace(10000000000l);
//
//            usageCx1.setUsage(DataCategory.RAWDATA, "aitman_eds", "NA", 2672);
//            usageCx1.setUsage(DataCategory.RAWDATA, "aitman_edswe", "NA", 124);
//            usageCx1.setUsage(DataCategory.RAWDATA, "aitman_fh", "NA", 576);
//
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_eds", "bwa", 25808);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_eds", "fastqc", 56552);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_eds", "gatk2", 27000096);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_eds", "mergetag", 108704);
//
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_edswe", "bwa", 25808);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_edswe", "fastqc", 56552);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_edswe", "gatk2", 27000096);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_edswe", "mergetag", 108704);
//
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_fh", "bwa", 25808);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_fh", "fastqc", 56552);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_fh", "gatk2", 27000096);
//            usageCx1.setUsage(DataCategory.ANALYSIS, "aitman_fh", "mergetag", 108704);
//
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_eds", "bwa", 25808);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_eds", "fastqc", 56552);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_eds", "gatk2", 27000096);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_eds", "mergetag", 108704);
//
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_edswe", "bwa", 25808);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_edswe", "fastqc", 56552);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_edswe", "gatk2", 27000096);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_edswe", "mergetag", 108704);
//
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_fh", "bwa", 25808);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_fh", "fastqc", 56552);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_fh", "gatk2", 27000096);
//            usageCx1.setUsage(DataCategory.RESULTS, "aitman_fh", "mergetag", 108704);
//
//            usageAx3.setUsedDiskSpace(10000000000l);
//
//            usageAx3.setUsage(DataCategory.RAWDATA, "aitman_eds", "NA", 2672);
//            usageAx3.setUsage(DataCategory.RAWDATA, "aitman_edswe", "NA", 92);
//            usageAx3.setUsage(DataCategory.RAWDATA, "aitman_fh", "NA", 552);
//
//            usageAx3.setUsage(DataCategory.ANALYSIS, "aitman_eds", "annovar", 334040);
//            usageAx3.setUsage(DataCategory.ANALYSIS, "aitman_edswe", "annovar", 392008);
//            usageAx3.setUsage(DataCategory.ANALYSIS, "aitman_fh", "annovar", 49232);
//
//            usageAx3.setUsage(DataCategory.RESULTS, "aitman_eds", "annovar", 49976);
//            usageAx3.setUsage(DataCategory.RESULTS, "aitman_edswe", "annovar", 100736);
//            usageAx3.setUsage(DataCategory.RESULTS, "aitman_fh", "annovar", 49232);

//            StorageStatsImpl stats = new StorageStatsImpl();
//            stats.addStorageResourceUsage(usageCx1);
//            stats.addStorageResourceUsage(usageAx3);

            StorageResourceUsageWriter writer = new StorageResourceUsagePrintWriter(retriever);

            writer.write(cx1, ax3, seq);

//            StorageResourceUsage usageCx1 = retriever.retrieveUsage(cx1);
//
//            for(String projectTag : usageCx1.getProjectTags()){
//
//                System.out.println(projectTag);
//
//            }
//
//            for(String workflow : usageCx1.getWorkflowNames()){
//
//                System.out.println(workflow);
//
//            }

            System.exit(0);

        }catch (MalformedURLException e){
            System.out.println(e);
        }

    }

}
