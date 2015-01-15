package uk.ac.ic.igf.datamanagement.storage;

import java.io.File;

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
 * Time: 14:25
 */
public interface StorageResourceUsageWriter {

    /**
     * Writes out the storage usage information for one or
     * more storage resources.
     *
     * @param storageResource
     */
    void write(StorageResource... storageResource);

}
