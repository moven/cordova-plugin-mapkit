package com.phonegap.plugins.mapkit;

import java.io.IOException;
import java.util.List;
import java.util.Locale;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.Toast;
import android.app.Dialog;
import android.content.ActivityNotFoundException;
import android.content.DialogInterface;
import android.content.Intent;
import android.location.Address;
import android.location.Geocoder;
import android.net.Uri;
import android.provider.Settings;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.GooglePlayServicesNotAvailableException;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap.OnCameraChangeListener;
import com.google.android.gms.maps.GoogleMap.OnInfoWindowClickListener;
import com.google.android.gms.maps.GoogleMapOptions;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.MapsInitializer;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.BitmapDescriptor;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.VisibleRegion;

public class MapKit extends CordovaPlugin {

    protected ViewGroup root; // original Cordova layout
    protected RelativeLayout main; // new layout to support map
    protected MapView mapView;
    private CallbackContext resumeCallbackContext;
    private String TAG = "MapKitPlugin";

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        main = new RelativeLayout(cordova.getActivity());
    }

    public void showMap(final JSONObject options, final CallbackContext cCtx) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    final int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(cordova.getActivity());
                    if (resultCode == ConnectionResult.SUCCESS) {
                        mapView = new MapView(cordova.getActivity(),
                                new GoogleMapOptions());
                        root = (ViewGroup) webView.getParent();
                        root.removeView(webView);
                        main.addView(webView);

                        double latitude = 0, longitude = 0;
                        double density = main.getResources().getDisplayMetrics().density;
                        int height = LayoutParams.MATCH_PARENT;
                        int width = LayoutParams.MATCH_PARENT;
                        int bottom = 0;

                        try {
                            height = options.has("height") ? options.getInt("height") : height;
                            latitude = options.getDouble("lat");
                            longitude = options.getDouble("lon");
                            bottom = options.has("bottom") ? (int) (density * options.getDouble("bottom")) : bottom;
                        } catch (JSONException e) {
                            LOG.e(TAG, "Error reading options");
                        }

                        cordova.getActivity().setContentView(main);

                        try {
                            MapsInitializer.initialize(cordova.getActivity());
                        } catch (GooglePlayServicesNotAvailableException e) {
                            e.printStackTrace();
                        }

                        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(width, height);
                        params.addRule(RelativeLayout.ALIGN_PARENT_TOP,
                                RelativeLayout.TRUE);
                        params.addRule(RelativeLayout.ALIGN_PARENT_LEFT,
                                RelativeLayout.TRUE);
                        params.setMargins(0, 0, 0, bottom);

                        mapView.setLayoutParams(params);
                        mapView.onCreate(null);
                        mapView.onResume(); // FIXME: I wish there was a better way
                                            // than this...
                        main.addView(mapView);

                        // Moving the map to lot, lon
                        mapView.getMap().moveCamera(
                                CameraUpdateFactory.newLatLngZoom(new LatLng(
                                        latitude, longitude), 15));

                        mapView.getMap().setOnInfoWindowClickListener(new OnInfoWindowClickListener() {
                            public void onInfoWindowClick(Marker marker) {
                                openMapsApp(marker);
                            }
                        });

                        mapView.getMap().setMyLocationEnabled(true);

                        mapView.getMap().setOnCameraChangeListener(new OnCameraChangeListener() {
                            @Override
                            public void onCameraChange(CameraPosition cp) {
                                if (cp.target == null) {
                                    return;
                                }
                                VisibleRegion vr = mapView.getMap().getProjection().getVisibleRegion();
                                double lonSpan = Math.abs(vr.latLngBounds.southwest.longitude - vr.latLngBounds.northeast.longitude);
                                double latSpan = Math.abs(vr.latLngBounds.northeast.latitude - vr.latLngBounds.southwest.latitude);
                                fireDocumentEvent("mapmove",
                                        String.format("{ location: { lat: %f, lon: %f }, delta: { lat: %f, lon: %f } }",
                                        cp.target.latitude, cp.target.longitude, latSpan, lonSpan)
                                );
                            }
                        });
                        cCtx.success();

                    } else if (resultCode == ConnectionResult.SERVICE_MISSING ||
                               resultCode == ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED ||
                               resultCode == ConnectionResult.SERVICE_DISABLED) {
                        Dialog dialog = GooglePlayServicesUtil.getErrorDialog(resultCode, cordova.getActivity(), 1,
                                    new DialogInterface.OnCancelListener() {
                                        @Override
                                        public void onCancel(DialogInterface dialog) {
                                            cCtx.error("com.google.android.gms.common.ConnectionResult " + resultCode);
                                        }
                                    }
                                );
                        dialog.show();
                    }

                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::showMap(): An exception occured");
        }
    }

    private void openMapsApp(Marker marker) {
        LatLng pos = marker.getPosition();
        String uri = String.format(Locale.ENGLISH, "http://maps.google.com/maps?&daddr=%f, %f (%s)&directionsmode=walking&views=transit", pos.latitude, pos.longitude, marker.getTitle());
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(uri));
        intent.setClassName("com.google.android.apps.maps", "com.google.android.maps.MapsActivity");
        try
        {
            cordova.getActivity().startActivity(intent);
        }
        catch(ActivityNotFoundException ex)
        {
            try
            {
                Intent unrestrictedIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(uri));
                cordova.getActivity().startActivity(unrestrictedIntent);
            }
            catch(ActivityNotFoundException innerEx)
            {
                Toast.makeText(cordova.getActivity().getApplicationContext(), "Please install a maps application", Toast.LENGTH_LONG).show();
            }
        }
    }

    private void fireDocumentEvent(String method, String data) {
        webView.loadUrl(String.format("javascript:cordova.fireDocumentEvent('%s', %s);", method, data));
    }

    private void hideMap(final CallbackContext cCtx) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
                        mapView.onDestroy();
                        main.removeView(webView);
                        main.removeView(mapView);
                        root.addView(webView);
                        cordova.getActivity().setContentView(root);
                        mapView = null;
                        cCtx.success();
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::hideMap(): An exception occured");
        }
    }

    public void addMapPins(final JSONArray pins, final CallbackContext cCtx) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
                        try {
                            for (int i = 0, j = pins.length(); i < j; i++) {
                                double latitude = 0, longitude = 0;
                                JSONObject options = pins.getJSONObject(i);
                                latitude = options.getDouble("lat");
                                longitude = options.getDouble("lon");

                                MarkerOptions mOptions = new MarkerOptions();

                                mOptions.position(new LatLng(latitude, longitude));
                                if(options.has("title")) {
                                    mOptions.title(options.getString("title"));
                                }
                                if(options.has("snippet")) {
                                    mOptions.snippet(options.getString("snippet"));
                                }
                                if(options.has("icon")) {
                                    BitmapDescriptor bDesc = getBitmapDescriptor(options);
                                    if(bDesc != null) {
                                      mOptions.icon(bDesc);
                                    }
                                }
                                // adding Marker
                                // This is to prevent non existing asset resources to crash the app
                                try {
                                    mapView.getMap().addMarker(mOptions);
                                } catch(NullPointerException e) {
                                    LOG.e(TAG, "An error occurred when adding the marker. Check if icon exists");
                                }
                            }
                            cCtx.success();
                        } catch (JSONException e) {
                            e.printStackTrace();
                            LOG.e(TAG, "An error occurred while reading pins");
                            cCtx.error("An error occurred while reading pins");
                        }
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::addMapPins(): An exception occured");
        }
    }

    private BitmapDescriptor getBitmapDescriptor( final JSONObject iconOption ) {
        try {
            Object o = iconOption.get("icon");
            String type = null, resource = null;
            if( o.getClass().getName().equals("org.json.JSONObject" ) ) {
                JSONObject icon = (JSONObject)o;
                if(icon.has("type") && icon.has("resource")) {
                    type = icon.getString("type");
                    resource = icon.getString("resource");
                    if(type.equals("asset")) {
                        return BitmapDescriptorFactory.fromAsset(resource);
                    }
                }
            } else {
                //this is a simple change in the icon's color
                return BitmapDescriptorFactory.defaultMarker(Float.parseFloat(o.toString()));
            }
        } catch (JSONException e){
            e.printStackTrace();
        }
        return null;
    }

    public void setLocation(final JSONObject options, final CallbackContext cCtx) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
                        double latitude = 0;
                        double longitude = 0;
                        double latitudeDelta = 0.05;
                        double longitudeDelta = 0.05;

                        try {
                            latitude = options.getDouble("lat");
                            longitude = options.getDouble("lon");
                            latitudeDelta = options.getDouble("latDelta");
                            longitudeDelta = options.getDouble("lonDelta");
                        } catch (JSONException e) {
                            LOG.e(TAG, "Error reading options");
                        }

                        LatLngBounds bounds = new LatLngBounds(new LatLng(latitude-latitudeDelta/2, longitude-longitudeDelta/2), new LatLng(latitude+latitudeDelta/2, longitude+longitudeDelta/2));

                        mapView.getMap().moveCamera(CameraUpdateFactory.newLatLngBounds(bounds, 10));
                        cCtx.success();
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::setLocation(): An exception occured");
        }
    }

    public void reverseGeocode(final JSONObject options, final CallbackContext cCtx) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    double latitude = 0;
                    double longitude = 0;

                    try {
                        latitude = options.getDouble("lat");
                        longitude = options.getDouble("lon");
                    } catch (JSONException e) {
                        LOG.e(TAG, "Error reading options");
                    }

                    Geocoder geocoder = new Geocoder(cordova.getActivity().getApplicationContext());
                    try {
                        List<Address> addresses = geocoder.getFromLocation(latitude, longitude, 1);
                        if (addresses.size() > 0) {
                            Address address = addresses.get(0);
                            cCtx.success(returnAddressJSON(address));
                        } else {
                            // perhaps throw an error instead.
                            //cCtx.success();
                        }
                    } catch (IOException e) {
                        e.printStackTrace();
                        cCtx.error("MapKitPlugin::reverseGeocode(): An exception occured: " + e.getMessage());
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::reverseGeocode(): An exception occured: " + e.getMessage());
        }
    }

    public JSONObject returnAddressJSON(Address address) {
        JSONObject o = new JSONObject();

        try {
            JSONArray addressLines = new JSONArray();
            int len = address.getMaxAddressLineIndex();
            for (int i=0;i<=len;i++){
                addressLines.put(address.getAddressLine(i));
            }
            o.put("FormattedAddressLines", addressLines);
            o.put("Street", (address.getMaxAddressLineIndex() >= 0) ? address.getAddressLine(0) : "");
            o.put("Country", address.getCountryName());
            o.put("CountryCode", address.getCountryCode());
            o.put("ZIP", address.getPostalCode());
            o.put("Name", address.getLocality());
            o.put("SubAdministrativeArea", address.getSubAdminArea());
            o.put("State", address.getAdminArea());
            o.put("City", address.getLocality());
            o.put("Throughfare", address.getThoroughfare());
            o.put("SubThroughfare", address.getSubThoroughfare());
            o.put("SubLocality", address.getSubLocality());
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return o;
    }


    public void clearMapPins(final CallbackContext cCtx) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
                        mapView.getMap().clear();
                        cCtx.success();
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::clearMapPins(): An exception occured");
        }
    }

    public void changeMapType(final JSONObject options, final CallbackContext cCtx) {
        try{
            cordova.getActivity().runOnUiThread(new Runnable() {

                @Override
                public void run() {
                    if( mapView != null ) {
                        int mapType = 0;
                        try {
                            mapType = options.getInt("mapType");
                        } catch (JSONException e) {
                            LOG.e(TAG, "Error reading options");
                        }

                        //Don't want to set the map type if it's the same
                        if(mapView.getMap().getMapType() != mapType) {
                            mapView.getMap().setMapType(mapType);
                        }
                    }

                    cCtx.success();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::changeMapType(): An exception occured ");
        }
    }

    public void openLocationSettings (final CallbackContext cCtx) {
        resumeCallbackContext = cCtx;
        Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
        cordova.getActivity().startActivity(intent);
    }

    public boolean execute(String action, JSONArray args,
            CallbackContext callbackContext) throws JSONException {
        if (action.compareTo("showMap") == 0) {
            showMap(args.getJSONObject(0), callbackContext);
        } else if (action.compareTo("hideMap") == 0) {
            hideMap(callbackContext);
        } else if (action.compareTo("destroyMap") == 0) {
            hideMap(callbackContext);
        } else if (action.compareTo("addMapPins") == 0) {
            addMapPins(args.getJSONArray(0), callbackContext);
        } else if (action.compareTo("clearMapPins") == 0) {
            clearMapPins(callbackContext);
        } else if( action.compareTo("changeMapType") == 0 ) {
            changeMapType(args.getJSONObject(0), callbackContext);
        } else if (action.compareTo("setLocation") == 0) {
            setLocation(args.getJSONObject(0), callbackContext);
        } else if (action.compareTo("reverseGeocode") == 0) {
            reverseGeocode(args.getJSONObject(0), callbackContext);
        } else if (action.compareTo("openLocationSettings") == 0) {
            openLocationSettings(callbackContext);
        }
        LOG.d(TAG, action);

        return true;
    }

    @Override
    public void onPause(boolean multitasking) {
        LOG.d(TAG, "MapKitPlugin::onPause()");
        if (mapView != null) {
            mapView.onPause();
        }
        super.onPause(multitasking);
    }

    @Override
    public void onResume(boolean multitasking) {
        LOG.d(TAG, "MapKitPlugin::onResume()");
        if (mapView != null) {
            mapView.onResume();
        }
        if (resumeCallbackContext != null) {
            resumeCallbackContext.success();
            resumeCallbackContext = null;
        }
        super.onResume(multitasking);
    }

    @Override
    public void onDestroy() {
        LOG.d(TAG, "MapKitPlugin::onDestroy()");
        if (mapView != null) {
            mapView.onDestroy();
        }
        super.onDestroy();
    }
}