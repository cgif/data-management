package uk.ac.ic.igf.datamanagement.storage.impl;

import sun.security.util.Password;
import uk.ac.ic.igf.datamanagement.storage.StorageResource;

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
 * Time: 16:28
 */
public class StorageResourceImpl implements StorageResource {

    private String resourceName;
    private URL resourceUrl;

    public StorageResourceImpl(String resourceName, URL resourceUrl){
        this.resourceName=resourceName;
        this.resourceUrl=resourceUrl;
    }

    /**
     * Returns the name of the storage resource.
     *
     * @return storage resource name
     */
    @Override
    public String getResourceName() {
        return resourceName;
    }

    /**
     * Sets the name of the storage resource
     *
     * @param name of the storage resource
     */
    @Override
    public void setResourceName(String name) {
        this.resourceName=name;
    }

    /**
     * Returns the storage resource URL
     *
     * @return the storage resource URL
     */
    @Override
    public URL getResourceUrl() {
        return resourceUrl;
    }

    /**
     * Sets the storage resource URL
     *
     * @param url of the storage resource
     */
    @Override
    public void setResourceUrl(URL url) {
        this.resourceUrl=url;
    }

    @Override
    public String toString() {
        return "StorageResourceImpl{" +
                "resourceName='" + resourceName + '\'' +
                ", resourceUrl=" + resourceUrl +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        StorageResourceImpl that = (StorageResourceImpl) o;

        if (!resourceName.equals(that.resourceName)) return false;

        return true;
    }

    @Override
    public int hashCode() {
        return resourceName.hashCode();
    }

}
