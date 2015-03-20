package uk.ac.ic.igf.datamanagement.impl;

import uk.ac.ic.igf.datamanagement.EmailAccount;

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
 * Time: 13:50
 */
public class EmailAccountImpl implements EmailAccount {

    public String name;
    public String smtpHost;
    public String userName;
    public char[] password;
    public String sender;

    public EmailAccountImpl(String name) {
        this.name = name;
    }

    @Override
    public String getName() { return name; }

    @Override
    public void setName(String name) { this.name=name; }

    @Override
    public String getSmtpHost() {
        return smtpHost;
    }

    @Override
    public String getUserName() {
        return userName;
    }

    @Override
    public char[] getPassword() {
        return password;
    }

    @Override
    public String getSender() {
        return sender;
    }

    @Override
    public void setSmtpHost(String smtpHost) {
        this.smtpHost=smtpHost;
    }

    @Override
    public void setUserName(String userName) {
        this.userName=userName;
    }

    @Override
    public void setPassword(char[] password) {
        this.password=password;
    }

    @Override
    public void setSender(String sender) {
        this.sender=sender;
    }

    @Override
    public String toString() {
        return "EmailServerImpl{" +
                "name='" + name + '\'' +
                ", smtpHost='" + smtpHost + '\'' +
                ", userName='" + userName + '\'' +
                ", sender='" + sender + '\'' +
                '}';
    }
}
