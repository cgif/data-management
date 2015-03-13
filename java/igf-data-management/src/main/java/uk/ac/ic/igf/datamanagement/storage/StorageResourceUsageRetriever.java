package uk.ac.ic.igf.datamanagement.storage;

import java.util.List;
import java.util.Map;

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
 * Time: 17:43
 */
public interface StorageResourceUsageRetriever {

    /**
     * Returns the storage resource usage for all registered resources.
     * @return list of storage resource usage objects
     */
    List<StorageResourceUsage> retrieveUsage(StorageResource... storageResource);

    /**
     * Returns the storage usage for a specific resource.
     * @return the storage resource usage
     */
    StorageResourceUsage retrieveUsage(StorageResource storageResource);

}
