package uk.ac.ic.igf.datamanagement;

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
 * Date: 13/11/14
 * Time: 13:48
 */
public interface EmailAccount {

    public String getName();

    public String getSmtpHost();

    public String getUserName();

    public char[] getPassword();

    public String getSender();

    public void setName(String name);

    public void setSmtpHost(String smtpHost);

    public void setUserName(String userName);

    public void setPassword(char[] password);

    public void setSender(String sender);

}
