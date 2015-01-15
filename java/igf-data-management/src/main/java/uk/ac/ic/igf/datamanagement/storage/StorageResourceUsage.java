package uk.ac.ic.igf.datamanagement.storage;

import java.util.Map;
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
 * Date: 08/10/14
 * Time: 16:25
 */
public interface StorageResourceUsage {

    /**
     * Returns the storage resource.
     * @return the storage resource.
     */
    StorageResource getStorageResource();

    /**
     * Sets the storage resource.
     * @param storageResource the storage resource
     */
    void setStorageResource(StorageResource storageResource);

    /**
     * Returns the total used disk space in kilobytes
     * @return the disk space in kilobytes
     */
    long getUsedDiskSpace();

    /**
     * Sets the total used disk space in kilobytes.
     * @param diskSpace the diskspace in kilobytes
     */
    void setUsedDiskSpace(long diskSpace);

    /**
     * Returns the total disk space in kilobytes
     * @return total available disk space
     */
    long getTotalDiskSpace();

    /**
     * Sets the total disk space.
     * @param diskSpace disk space in kilobytes
     */
    void setTotalDiskSpace(long diskSpace);

    /**
     * Returns the total data storage usage in kilobytes for the specified
     * data category.
     *
     * @return storage usage in kb
     */
    long getUsage(DataCategory category);

    /**
     * Returns the storage usage in kilobytes for the specified
     * workflow, project and data category.
     *
     * @param workflowName the name of the workflow
     * @param projectTag the project tag
     * @param category the data category
     * @return storage usage in kb
     */
    public long getUsage(DataCategory category, String projectTag, String workflowName);

    /**
     *  Sets the storage usage for a data category, project and workflow.
     *
     * @param category the data category
     * @param projectTag the project tag
     * @param workflow the workflow
     * @param usage the usage in kilobytes
     */
    void setUsage(DataCategory category, String projectTag, String workflow, long usage);

    /**
     * Returns the total data storage usage in kilobytes for the specified
     * project.
     *
     * @param projectTag the project tag
     * @return storage usage in kb
     */
    long getUsageByProject(String projectTag);

    /**
     * Returns the storage usage in kilobytes for the specified
     * project and data category.
     *
     * @param projectTag the project tag
     * @return storage usage in kb
     */
    long getUsageByProject(String projectTag, DataCategory category);

    /**
     * Returns the total storage usage in kilobytes for the specified
     * workflow.
     *
     * @param workflowName the name of the workflow
     * @return storage usage in kb
     */
    long getUsageByWorkflow(String workflowName);

    /**
     * Returns the storage usage in kilobytes for the specified
     * workflow and data category.
     *
     * @param workflowName the name of the workflow
     * @param category the data category
     * @return storage usage in kb
     */
    long getUsageByWorkflow(String workflowName, DataCategory category);

    /**
     * Returns a set of project tags of projects for which data is stored on the storage resource.
     *
     * @return set of project tags
     */
    Set<String> getProjectTags();

    /**
     * Returns a set of workflow names for which data is stored on the storage resource.
     *
     * @return set of workflow names
     */
    Set<String> getWorkflowNames();

    /**
     * Returns a set of workflow names for which data is stored on the storage resource.
     *
     * @param projectTag the data category
     * @return set of workflow names
     */
    public Set<String> getWorkflowNames(String projectTag);

}
