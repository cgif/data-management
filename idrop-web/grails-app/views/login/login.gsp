<!DOCTYPE html>
<html lang="en">
    <head>
        <title>iDrop-web - iRODS IGF</title>
        <meta name="layout" content="basic" />
        <%-- mcosso custom style --%>
        <link rel="stylesheet" href="${resource(dir:'css',file:'mybootstrap.css')}" />
        <style type="text/css">
            /* Override some defaults */
            html,body {
            background-color: #eee;
            font:normal 12px verdana;
            }

            body {
            padding-top: 40px;
            }

            .container {
            width: 600px;
            }

            /* The white background content wrapper */
            .container>.content {
            background-color: #fff;
            padding: 20px;
            margin: 0 -20px;
            -webkit-border-radius: 10px 10px 10px 10px;
            -moz-border-radius: 10px 10px 10px 10px;
            border-radius: 10px 10px 10px 10px;
            -webkit-box-shadow: 0 1px 2px rgba(0, 0, 0, .15);
            -moz-box-shadow: 0 1px 2px rgba(0, 0, 0, .15);
            box-shadow: 0 1px 2px rgba(0, 0, 0, .15);
            }

            .login-form {
            margin-left: 65px;
            }

            legend {
            margin-right: -50px;
            font-weight: bold;
            color: #404040;
            }
        </style>
    </head>

    <body>
        <div class="container">
            <div class="row-fluid content">
                <div class="span12">
                    <g:hasErrors bean="${loginCommand}">
                        <div class="alert alert-error">
                            <ul>
                                <g:eachError var="err" bean="${loginCommand}">
                                    <li><g:message error="${err}" /></li>
                                    </g:eachError>
                            </ul>
                        </div>
                    </g:hasErrors>
                </div>
                <div class="span12">

                    <g:form id="normalLogin" method="post" controller="login"
                        action="authenticate" class="loginForm">
                        <g:hiddenField name="usePresets" id="usePresets"
                        value="${loginCommand.usePresets}" />
                        <fieldset>                                           
                            <legend>
                                <img src="${resource(dir:'images',file:'90OX-em3_400x400.png')}" style="padding-bottom: 30px" ><g:message code="message.igf" />
                            </legend>

                            <h2><g:message code="message.login" /></h2>
                            <g:if test="${loginCommand.usePresets}">

                                <g:hiddenField name="host" id="host" value="${loginCommand.host}" />
                                <g:hiddenField name="port" id="port" value="${loginCommand.port}" />
                                <g:hiddenField name="zone" id="zone" value="${loginCommand.zone}" />
                                <g:hiddenField name="resource" id="resource" value="${loginCommand.resource}" />
                                <%-- mcosso
                                <g:hiddenField name="authMethod" id="authMethod" value="${loginCommand.authMethod}" />
                                 --%>
                            </g:if>                                                        
                            <g:else>
                                <label><g:message code="text.host" />:</label>
                                <input type="text" class="input-text" name="host" id="host" value="${loginCommand.host}" />
                                <label><g:message code="text.port" />:</label>
                                <input type="text" class="input-text" name="port" id="port" value="${loginCommand.port}" />
                                <label><g:message code="text.zone" />:</label>
                                <input type="text" class="input-text" name="zone" id="zone" value="${loginCommand.zone}" />
                            </g:else>

<%--                
<label><g:message code="text.guest.login" />:</label>

<g:checkBox name="useGuestLogin" id="useGuestLogin"
value="${loginCommand.useGuestLogin}"
onclick="toggleGuestLogin()" />
--%>

                            <label class="userLoginData"><g:message code="text.user" />:</label> 
                            <input type="text" class="input-text userLoginData" name="user" id="user" value="${loginCommand.user}" /> 
                            <label class="userLoginData"><g:message code="text.password" />:</label> 
                            <input type="password" class="input-text userLoginData" name="password" id="password" value="${loginCommand.password}" />

                            <label><g:message code="text.auth.method" />:</label>

                            <g:select class="userLoginData" name="authMethod" from="${['Standard', 'PAM']}"
                            value="${loginCommand.authMethod}" />
                            <button id="login" name="login" style="margin-left: 150px; margin-top: 20px; margin-bottom: 20px;" type="submit">
                                <g:message code="text.login" />
                            </button>

                            <g:if test="${!loginCommand.usePresets}">
                                <div>
                                    <div>
                                        <label><g:message code="text.resource" />:</label>
                                    </div>
                                    <div>
                                        <input type="text" class="input-text" name="resource"
                                        id="resource" value="${loginCommand.resource}" />
                                        <stong> <g:message code="text.optional" /> <strong></strong>
                                        </stong>
                                    </div>
                                </div>
                            </g:if>
                        </fieldset>
                    </g:form>

                                <!--end-normalLogin-->
                </div>

            </div>

        </div>
        <%-- mcosso
        <script type="text/javascript">
        $(function() {
                toggleGuestLogin();

        });

        function toggleGuestLogin() {
                var checkVal = $("#useGuestLogin").attr("checked");
                if (checkVal) {
                        $(".userLoginData").hide("slow");

                } else {
                        $(".userLoginData").show("slow");
                }
        }
</script>
--%>
    </body>
</html>




