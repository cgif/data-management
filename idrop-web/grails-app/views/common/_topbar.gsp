
<div class="navbar navbar-fixed-top navbar-inverse">
    <div class="navbar-inner">
        <g:ifAuthenticated>
            <a class="brand" href="#">
                <img src="${resource(dir:'images',file:'90OX-em3_400x400.png')}" style="height:30px;padding-left:10px">
                <g:message code="message.igf" />
            </a>
            <a class="" href="#">

                <g:link controller="login" action="logout">
                    <img style="float:right;padding-right:30px;padding-top:10px" src="${resource(dir:'images',file:'exit.png')}" title="<g:accountInfo />" alt="<g:accountInfo />">
                </g:link>
            </a>
        </g:ifAuthenticated>
        <ul class="nav">
            <g:ifAuthenticated>

        <!--  menu items shown if user has been authenticated -->

                <li id="topbarHome" class="topbarItem">
                    <g:link controller="home" action="index">
                        <g:message code="text.home" />
                    </g:link>
                </li> 
                <li id="topbarBrowser" class="topbarItem">
                    <g:link controller="browse" action="index">
                        <g:message code="text.browse" />
                    </g:link>
                </li>
                 <li id="topbarBrowser" class="topbarItem">
                     &nbsp;&nbsp;
                 </li>  
                <li id="topbarBrowser" class="topbarItem">
                    <%-- mcosso added search for name --%>
                    <g:form  name="frmSearch" controller="search" action="search" onsubmit="return validateForm()">
                        <input type="text" class="input-text" name="searchTerm" id="searchTerm" value="" style="margin-top: 10px"/> 
                        <button id="searchObject" value="search" type="submit"><g:message code="text.search"/></button>
                    </g:form>
                </li>
                <g:ifNotGuestAccount>
                    <g:if test="${grailsApplication.config.idrop.config.use.userprofile==true}">
                        <li id="topbarPreferences" class="topbarItem"><g:link controller="profile" action="index">Profile</g:link></li>
                        </g:if>
                    </g:ifNotGuestAccount>
                         <%--   mcosso
                <li id="topbarSearch" class="dropdown">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                        <g:message code="text.search" /><b class="caret"></b></a>
                    <ul class="dropdown-menu">
                        <li><a href="#" id="searchFileName"><g:link controller="search" action="index">Search By File Name</a></g:link></li>
                        <li><a href="#" id="searchTag"><g:link controller="tags" action="index"><g:message code="text.tags" /></g:link></li>
                       <!--  <li><a href="#" id="searchMetadata" onclick="xxx()")>Search By Metadata</a></li>  -->
                    </ul>
                </li>
            
                <li id="topbarTools" class="dropdown">
                         <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                        <g:message code="text.tools" /><b class="caret"></b></a>
                         <ul class="dropdown-menu">
                                         <li><a href="https://github.com/DICE-UNC/idrop/wiki/iDrop-Installers" target="_blank">iDrop Desktop</a></li>
                                          <li id="topbarRule" class="topbarItem"><g:link controller="rule" action="delayExecQueue">User Rules</g:link></li>
                          </ul>
                </li>
              --%>      

                </g:ifAuthenticated>

            <li id="topbarAccount" class="">
                <%--  mcosso 
                <a href="#" class="" data-toggle="dropdown">
                    <g:ifAuthenticated> 
                        <g:message code="text.account" /> 
                        <g:ifNotGuestAccount>( <span id="accountZoneAndUserDisplay"><g:accountInfo /></span> )<b class="caret"></b> </g:ifNotGuestAccount>
                    </g:ifAuthenticated>
                </a>
                --%>
                <ul class="dropdown-menu">
                    <g:ifAuthenticated>
                        <li><g:link controller="login" action="logout"><g:message code="text.logout" /></g:link></li>
                        <%-- mcosso
                        <g:ifNotGuestAccount>
                               <li><a href="#" id="changePasswordButton"><g:link controller="login" action="changePasswordForm"><g:message code="text.change.password" /></g:link></a></li>
                        </g:ifNotGuestAccount>
                        <li><a href="#" id="setDefaultResourceButton"><g:link controller="login" action="defaultResource"><g:message code="text.set.default.resource" /></g:link></a></li>
                        --%>
                        </g:ifAuthenticated>
                        <g:ifNotAuthenticated>
                        <li><g:link href="#" id="loginButton" controller="login" action="login"><g:message code="text.login" /></g:link></li>
                        </g:ifNotAuthenticated>

                </ul>
            </li>
            <%-- mcosso
             <g:ifAuthenticated>
                      <li id="topbarShoppingCart" class="topbarItem"><g:link class="pull-right" controller="shoppingCart" action="index"><span id="shoppingCartToolbarLabel"><g:message code="text.shopping.cart" /></span></g:link></li>
             </g:ifAuthenticated>
             --%>
        </ul>
    </div>
</div>
<g:ifAuthenticated>
    <script>
	var currentZone = "${irodsAccount?.zone}";
	var currentUser = "${irodsAccount?.userName}";
        //$(function() {	
        //$("#accountZoneAndUserDisplay").html(currentZone + ":" + currentUser);
        //	});
    </g:ifAuthenticated>
</script>





