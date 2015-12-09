<head>
    <meta name="layout" content="mainNoSidebar" />
    <g:javascript library="mydrop/home" />
</head>

<ul class="nav nav-tabs" id="searchTabs">
    <li><a href="#tagCloudTab">File</a></li>
    <li><a href="#resultsTab">Search Results</a></li>
</ul>

<div class="tab-content">
    <g:form class="form-horizontal" controller="search" action="search">
        <div class="tab-pane active" id="tagCloudTab">
            <div style="padding: 10px;overflow:auto;">
                <div id="tagCloudDiv" style="height: 700px;width:auto;">
                        <!--  tag cloud div is ajax loaded -->
                    <label class="userLoginData"><g:message code="text.searchTerm" />:</label> 
                    <input type="text" class="input-text userLoginData" name="searchTerm" id="searchTerm" value="" /> 
                    <button id="changePassword" value="search" type="submit" ><g:message code="text.update"/></button>
                </div>
            </div>
        </div>
    </g:form>
    <div class="tab-pane"  id="resultsTab">
        <div id="resultsTabInner">
            <div>
                <table id="searchResultTable" class="table table-striped table-hover" cellspacing="0" cellpadding="0" border="0">
                    <thead>
                        <tr>
                            <th></th>
                            <th>
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

                    </th>
                    <th><g:message code="text.name" /></th>
                    <th><g:message code="text.type" /></th>
                    <th><g:message code="text.length" /></th>

                    </tr>
                    </thead>
                    <tbody>
                        <g:each in="${results}" var="entry">

                            <tr id="${entry.formattedAbsolutePath}">

                                <td><span class="ui-icon-circle-plus search-detail-icon  ui-icon"></span></td>
                                <td><g:checkBox name="selectDetail"
                                    value="${entry.formattedAbsolutePath}" checked="false" /> 
                                    <span class="setPaddingLeftAndRight">
                                        <g:link target="_blank" controller="browse" action="index"
                                            params="[mode: 'path', absPath: entry.formattedAbsolutePath]">
                                            <i class="icon-folder-open "></i>
                                        </g:link>
                                    </span>
                                </td>
                                <td>
                                    ${entry.nodeLabelDisplayValue}
                                </td>
                                <td>
                                    ${entry.objectType}
                                </td>
                                <td>
                                    ${entry.displayDataSize}
                                </td>
                            </tr>
                        </g:each>

                    </tbody>

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
        </div>
    </div>
</div>