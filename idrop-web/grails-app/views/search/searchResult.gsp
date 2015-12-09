<head>
    <meta name="layout" content="mainNoSidebar" />
    <g:javascript library="mydrop/home" />
</head>
<div>
    <h2>You searched for <i>"${searchTerm}"</i></h2>
    <table id="searchResultTable" class="table table-striped table-hover" cellspacing="0" cellpadding="0" border="0">
        <thead>
            <tr>
                <th></th>

                <th><g:message code="text.actions" /></th>
                <%-- mcosso
            <div class="btn-group">            
                <a class="btn dropdown-toggle" data-toggle="dropdown" href="#">Action
                    <span class="caret"></span></a>
                <ul class="dropdown-menu">
                    <li id="menuAddToCartDetails">
                        <a href="#addAllToCartDetails" onclick="addSelectedToCart()">
                            <g:message code="text.add.all.to.cart" />
                        </a>
                    </li>
                    <li id="menuDeleteDetails">
                        <a href="#deleteAllDetails" onclick="deleteSelected()">
                            <g:message code="text.delete.all" />
                        </a>
                    </li>
                <!-- dropdown menu links -->
                </ul>
            </div>
            --%>
                <th><g:message code="text.name" /></th>
                <%--<th><g:message code="text.type" /></th>--%>
                <th><g:message code="text.moodate" /></th>
                <th><g:message code="text.length" /></th>
            </tr>
        </thead>

        <g:each in="${results}" var="entry">
            <tr id="${entry.formattedAbsolutePath}">
                <td><span class="search-detail-icon  ui-icon"></span></td>
                <td>
                   <%-- <g:checkBox name="selectDetail" value="${entry.formattedAbsolutePath}" checked="false" /> --%>
                     <%-- mcosso g:link url="${'file/download' + entry.domainUniqueName}"--%>
                    <g:if test="${entry.objectType.toString().equals('DATA_OBJECT')}">
                        <i class="icon-download" onclick="downloadViaToolbarGivenPath('${entry.formattedAbsolutePath}');"></i>
                    </g:if>
                    <span class="setPaddingLeftAndRight">
                        <g:link target="_blank" controller="browse" action="index" params="[mode: 'path', absPath: entry.formattedAbsolutePath]">
                            <i class="icon-folder-open "></i>
                        </g:link>
                    </span>
                </td>
                <td>
                   <%--${entry.nodeLabelDisplayValue} --%>
                    ${entry.formattedAbsolutePath} 
                </td>
                <%--
                <td>
                    ${entry.objectType}
                </td>
--%>
                <td>
                    ${entry.modifiedAt}
                </td>
                <td>
                    ${entry.displayDataSize}
                </td>
            </tr>
        </g:each>
        <g:if test="${results.size()==0}">
            <tr>
                <td colspan="5">
                    No matching records found!
                </td>    
            </tr>
        </g:if>          
        <tfoot>
            <tr>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
            </tr>
        </tfoot>
    </table>
</div>