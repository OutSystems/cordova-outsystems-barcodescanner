package com.outsystems.plugins.barcodescanner;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Color;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.TextView;
import androidx.annotation.NonNull;
import com.journeyapps.barcodescanner.CaptureManager;
import com.journeyapps.barcodescanner.DecoratedBarcodeView;
import com.journeyapps.barcodescanner.ViewfinderView;

/**
 * Custom Scannner Activity extending from Activity to display a custom layout form scanner view.
 */
public class CustomScannerActivity extends Activity implements
        DecoratedBarcodeView.TorchListener {

    private CaptureManager capture;
    private DecoratedBarcodeView barcodeScannerView;
    private ImageButton switchFlashlightButton;
    private ViewfinderView viewfinderView;
    private boolean flashlightOn=false;
    private boolean isScanning=false;

    // For retrieving R.* resources, from the actual app package
    // (we can't use actual.application.package.R.* in our code as we
    // don't know the application package name when writing this plugin).
    private String package_name;
    private Resources resources;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_custom_scanner);

        String scanInstructions = getIntent().getStringExtra("SCAN_INSTRUCTIONS");
        String scanOrientation = getIntent().getStringExtra("SCAN_ORIENTATION");
        boolean scanLine = getIntent().getBooleanExtra("SCAN_LINE", true);
        boolean scanButtonVisible = getIntent().getBooleanExtra("SCAN_BUTTON", true);

        //barcodeScannerView = findViewById(R.id.zxing_barcode_scanner);
        //barcodeScannerView.setTorchListener(this);
        //switchFlashlightButton = findViewById(R.id.switch_flashlight);
        //viewfinderView = findViewById(R.id.zxing_viewfinder_view);

        setContentView(getResourceId("id/activity_custom_scanner"));
        barcodeScannerView = findViewById(getResourceId("id/zxing_barcode_scanner"));
        barcodeScannerView.setTorchListener(this);
        switchFlashlightButton = findViewById(getResourceId("id/switch_flashlight"));
        viewfinderView = findViewById(getResourceId("id/zxing_viewfinder_view"));

        if (!scanButtonVisible) {
            View scanBtn = findViewById(R.id.scan_button);
            scanBtn.setVisibility(View.GONE);
        }

        if (scanOrientation == "landscape") {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        } else if (scanOrientation == "portrait") {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
        }


        // Load and use views afterwards
        TextView statusView = (TextView)findViewById(R.id.zxing_status_view);
        statusView.setText(scanInstructions);

        // if the device does not have flashlight in its camera,
        // then remove the switch flashlight button...
        if (!hasFlash()) {
            switchFlashlightButton.setVisibility(View.GONE);
        }

        capture = new CaptureManager(this, barcodeScannerView);
        capture.initializeFromIntent(getIntent(), savedInstanceState);
        capture.setShowMissingCameraPermissionDialog(false);
        changeMaskColor(null);
        changeLaserVisibility(scanLine);

    }

    @Override
    protected void onResume() {
        super.onResume();
        capture.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        capture.onPause();
    }

    private int getResourceId (String typeAndName)
    {
        if(package_name == null) package_name = getApplication().getPackageName();
        if(resources == null) resources = getApplication().getResources();
        return resources.getIdentifier(typeAndName, null, package_name);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        capture.onDestroy();
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        capture.onSaveInstanceState(outState);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        return barcodeScannerView.onKeyDown(keyCode, event) || super.onKeyDown(keyCode, event);
    }

    /**
     * Check if the device's camera has a Flashlight.
     * @return true if there is Flashlight, otherwise false.
     */
    private boolean hasFlash() {
        return getApplicationContext().getPackageManager()
                .hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH);
    }

    public void scan(View view) {
        capture.decode();
    }

    public void closeScreen(View view) {
        this.finish();
    }

    public void switchFlashlight(View view) {
        if (flashlightOn) {
            barcodeScannerView.setTorchOff();
        } else {
            barcodeScannerView.setTorchOn();
        }
    }

    public void changeMaskColor(View view) {
        int color = Color.argb(100, 0, 0, 0);
        viewfinderView.setMaskColor(color);
    }

    public void changeLaserVisibility(boolean visible) {
        viewfinderView.setLaserVisibility(visible);
    }

    @Override
    public void onTorchOn() {
        flashlightOn = true;
    }

    @Override
    public void onTorchOff() {
        flashlightOn = false;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        capture.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }
}
