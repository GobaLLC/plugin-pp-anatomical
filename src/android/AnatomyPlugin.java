package plugin.anatomical;

import android.content.Intent;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

/**
 * This class echoes a string called from JavaScript.
 */
public class AnatomyPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("presentAnatomyView")) {
            String message = args.getString(0);
            this.presentAnatomyView(message, callbackContext);
            return true;
        }
        return false;
    }

    private void presentAnatomyView(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            Intent intent = new Intent(cordova.getActivity(), AnatomyActivity.class);
            intent.putExtra("jsonData", message);
            cordova.getActivity().startActivity(intent);

            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }
}
