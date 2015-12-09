<%@page import="org.irods.jargon.core.query.MetaDataAndDomainData" %>
<%@page import="org.irods.jargon.usertagging.domain.IRODSSharedFileOrCollection" %>
<%-- mcosso add title --%>
<h2>Data available</h2>
<table class="table table-striped table-hover">
    <thead>
        <tr>
            <th></th>
            <th><g:message code="text.actions" /></th>
            <th><g:message code="text.name" /></th>
            <th><g:message code="text.description" /></th>
        </tr>
    </thead>
    <tbody>
        <g:each in="${listing}" var="entry">
            <tr>
                <g:if test="${entry.metadataDomain == MetaDataAndDomainData.MetadataDomain.COLLECTION}">
                    <td></td>
                    <td>
                        <span class="setPaddingLeftAndRight">
                            <g:link controller="browse" action="index" params="[mode: 'path', absPath: entry.domainUniqueName]">
                                <i class="icon-folder-open "></i>
                            </g:link>
                        </span>
                        <span class="setPaddingLeftAndRight">
                            <i class="icon-upload " onclick="quickviewUpload('${entry.domainUniqueName}')"></i>
                        </span>
                    </td>
                    <td>${entry.domainUniqueName}</td> 
                   
                </g:if>
                <g:else>
                    <td></td>
                    <td>
                        <span class="setPaddingLeftAndRight">
                <%-- mcosso g:link url="${'file/download' + entry.domainUniqueName}"--%>
                            <i class="icon-download" onclick="downloadViaToolbarGivenPath('${entry.domainUniqueName}');"></i>
                            <span class="setPaddingLeftAndRight">
                                <g:link controller="browse" action="index" params="[mode: 'path', absPath: entry.domainUniqueName]">
                                    <i class="icon-folder-open "></i>
                                </g:link>
                            </span>
<%--/g:link--%>                        <%-- XXXXX   deleteMetadata()  --%>
                        </span>
                    </td>
                    <td>${entry.domainUniqueName}</td> <td>${entry.description}</td>
                    <td>
                </td>
                    
                </g:else>
            </tr>
        </g:each>
        <g:if test="${listing.size()==0}">
            <tr>
                <td colspan="4">
                    No records found!
                </td>    
            </tr>
        </g:if> 
    </tbody>

</table>
<script>

    /**
    * Show the uplaod dialog using the hidden path in the info view
    */
    function quickviewUpload(path) {
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    showUploadDialogUsingPath(path);


    }
</script>