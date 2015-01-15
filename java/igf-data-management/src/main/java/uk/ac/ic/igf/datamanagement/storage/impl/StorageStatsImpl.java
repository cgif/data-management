package uk.ac.ic.igf.datamanagement.storage.impl;

import uk.ac.ic.igf.datamanagement.storage.DataCategory;
import uk.ac.ic.igf.datamanagement.storage.StorageResourceUsage;
import uk.ac.ic.igf.datamanagement.storage.StorageStats;

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
 * Date: 24/09/14
 * Time: 14:32
 */
public class StorageStatsImpl implements StorageStats {

    Map<String, StorageResourceUsage> storageResourceUsageMap = new TreeMap<>();



    /**
     * Returns storage usage for all resources.
     *
     * @return a list of storage resource usage objects
     */
    @Override
    public List<StorageResourceUsage> getStorageResourceUsage() {
        return new ArrayList<>(storageResourceUsageMap.values());
    }

    /**
     * Returns the storage usage for the specified resource.
     *
     * @param resourceName the name of the resource
     * @return a storage resource usage object
     */
    @Override
    public StorageResourceUsage getStorageResourceUsage(String resourceName) {
        return storageResourceUsageMap.get(resourceName);
    }

    protected void addStorageResourceUsage(StorageResourceUsage storageUsage){
        this.storageResourceUsageMap.put(storageUsage.getStorageResource().getResourceName(), storageUsage);
    }

    @Override
    public long getTotalStorageUsage(DataCategory dataCategory) {

        long retval = -1;

        for(StorageResourceUsage usage : storageResourceUsageMap.values()){

            retval = retval + usage.getUsage(dataCategory);

        }

        return retval;
    }

    @Override
    public long getTotalStorageUsage(DataCategory dataCategory, String projectTag) {

        long retval = -1;

        for(StorageResourceUsage usage : storageResourceUsageMap.values()){

            retval = retval + usage.getUsageByProject(projectTag, dataCategory);

        }

        return retval;

    }
}
