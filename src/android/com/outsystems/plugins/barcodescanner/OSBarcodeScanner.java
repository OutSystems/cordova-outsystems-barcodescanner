package com.outsystems.plugins.barcodescanner;
import android.content.Intent;
import android.util.Log;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import com.google.zxing.client.android.Intents;
import com.google.zxing.integration.android.IntentIntegrator;
import com.google.zxing.integration.android.IntentResult;

public class OSBarcodeScanner extends CordovaPlugin {

    public final int CUSTOMIZED_REQUEST_CODE = 0x0000ffff;
    static private CallbackContext _callbackContext;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        _callbackContext = callbackContext;

        if (action.equals("scan")) {
            String message = args.getString(0);
            this.scan(message, callbackContext);
            return true;
        }
        return false;
    }

    private void scan(String message, CallbackContext callbackContext) {

        IntentIntegrator integrator = new IntentIntegrator(this.cordova.getActivity());
        integrator.setOrientationLocked(false);
        integrator.setCaptureActivity(CustomScannerActivity.class);
        integrator.initiateScan();

        if (message != null && message.length() > 0) {
            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }

        this.cordova.setActivityResultCallback(this);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != CUSTOMIZED_REQUEST_CODE && requestCode != IntentIntegrator.REQUEST_CODE) {
            // This is important, otherwise the result will not be passed to the fragment
            super.onActivityResult(requestCode, resultCode, data);
            return;
        }

        IntentResult result = IntentIntegrator.parseActivityResult(resultCode, data);

        if(result.getContents() == null) {
            Intent originalIntent = result.getOriginalIntent();
            if (originalIntent == null) {
                _callbackContext.error("Cancelled");
            } else if(originalIntent.hasExtra(Intents.Scan.MISSING_CAMERA_PERMISSION)) {
                _callbackContext.error("Cancelled due to missing camera permission");
            }
        } else {
            _callbackContext.success(result.getContents());
        }
    }

}