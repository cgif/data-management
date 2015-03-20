package uk.ac.ic.igf.datamanagement.storage;

import java.net.URL;

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
 * Time: 16:21
 */
public interface StorageResource {

    /**
     * Returns the name of the storage resource.
     * @return storage resource name
     */
    String getResourceName();

    /**
     * Sets the name of the storage resource
     * @param name of the storage resource
     */
    void setResourceName(String name);

    /**
     * Returns the storage resource URL
     * @return the storage resource URL
     */
    URL getResourceUrl();

    /**
     * Sets the storage resource URL
     * @param url of the storage resource
     */
    void setResourceUrl(URL url);


}
