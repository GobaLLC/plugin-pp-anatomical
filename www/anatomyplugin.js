/*global cordova, module*/

module.exports = {
    presentAnatomyView: function (name, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "AnatomyPlugin", "presentAnatomyView", [name]);
    }
};
