<div id="collectionInfoToolbar" >
<%-- mcosso
<div id="collectionInfoToolbarMenu" class="btn-toolbar">
                
                <div id="collectionInfoButtonGroup1" class="btn-group">
                        <button id="setCollectionAsRoot" onclick="cibSetCollectionAsRoot()"><i class="icon-hand-left"></i><g:message
                                        code="text.set.as.root" /></button>
                                        
                                        
                        <g:if  test="${irodsStarredFileOrCollection}">
                                <button id="unstarCollection" onclick="cibUnstarCollection()"><i class="icon-star"></i><g:message
                                        code="text.unstar" /></button>
                        </g:if>
                        <g:else>
                                <button id="starCollection" onclick="cibStarCollection()"><i class="icon-star-empty"></i><g:message
                                        code="text.star" /></button>
                        </g:else>

                </div>

                <div id="collectionInfoButtonGroup2" class="btn-group">
                        <button id="addCollectionToCart" onclick="addToCartViaToolbar()"><i class="icon-shopping-cart"></i><g:message
                                        code="text.add.to.cart" /></button>
                        <button id="uploadViaBrowser" onclick="cibUploadViaBrowser()"><i class="icon-upload"></i><g:message
                                        code="text.upload" /></button>
                        <button id="bulkUploadViaBrowser" onclick="cibBulkUploadViaBrowser()"><i class="icon-upload"></i><g:message
                                        code="text.bulk.upload" /></button>
                        
                </div>
                <div id="collectionInfoButtonGroup3" class="btn-group">
                        <button id="newCollection" onclick="cibNewFolder()"><i class="icon-plus-sign"></i><g:message
                                        code="text.new.folder" /></button>
                        <button id="renameCollection" onclick="cibRenameCollection()"><i class="icon-pencil"></i><g:message
                                        code="text.rename" /></button>
                        <button id="deleteCollection" onclick="cibDeleteCollection()"><i class="icon-trash"></i><g:message
                                        code="text.delete" /></button>
                </div>
</div>
--%>
</div>

<script type="text/javascript">

    function cibSetCollectionAsRoot() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    setTreeToGivenPath(path);


    }

    /**
    * Show the uplaod dialog using the hidden path in the info view
    */
    function cibUploadViaBrowser() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    showUploadDialogUsingPath(path);


    }

    /**
    * Launch iDrop lite for bulk uplaod mode
    */
    function cibBulkUploadViaBrowser() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    showIdropLiteGivenPath(path, 2);
    }

    /**
    * Create a new folder underneath the current directory
    **/
    function cibNewFolder() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }
    newFolderViaToolbarGivenPath(path);
    }

    /**
    * Delete the collection currently displayed in the info view
    */
    function cibRenameCollection() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    renameViaToolbarGivenPath(path);
    }


    /**
    * call delete using the path in the info panel
    */
    function cibDeleteCollection() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    deleteViaToolbarGivenPath(path);
    }

    /**
    * favorite, or 'star' the collection currently displayed in the info view
    */
    function cibStarCollection() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    if (path == null) {
    setErrorMessage("No path was selected, use the tree to select an iRODS collection or file to star"); // FIXME:
    // i18n
    return;
    }

    lcShowBusyIconInDiv("#infoDialogArea");
    var url = "/browse/prepareStarDialog";

    var params = {
    absPath : path
    }

    lcSendValueWithParamsAndPlugHtmlInDiv(url, params, "#infoDialogArea", null);
    }

    /**
    * unfavorite favorite, or 'star' the collection currently displayed in the info view
    */
    function cibUnstarCollection() {
    var path = $("#infoAbsPath").val();
    if (path == null) {
    showErrorMessage(jQuery.i18n.prop('msg.path.missing'));
    return false;
    }

    if (path == null) {
    setErrorMessage("No path was selected, use the tree to select an iRODS collection or file to unstar"); // FIXME:
    // i18n
    return;
    }

    lcShowBusyIconInDiv("#infoDialogArea");
    var url = "/browse/unstarFile";

    var params = {
    absPath : path
    }

    showBlockingPanel();

    var jqxhr = $.post(context + url, params,
    function(data, status, xhr) {
    }, "html").success(
    function(returnedData, status, xhr) {
    var continueReq = checkForSessionTimeout(returnedData, xhr);
    if (!continueReq) {
    return false;
    }
    setMessage(jQuery.i18n.prop('msg_file_unstarred'));
    updateBrowseDetailsForPathBasedOnCurrentModel(selectedPath);
    closeStarDialog();
    unblockPanel();
    }).error(function(xhr, status, error) {
    setErrorMessage(xhr.responseText);
    closeStarDialog();
    unblockPanel();
    });

    }

</script>