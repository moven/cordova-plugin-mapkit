//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"

@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;

-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
    NSDictionary *options = [[NSDictionary alloc] init];
    [self createViewWithOptions:options];
}

- (void)reConfigureViewWithOptions:(NSDictionary *)options {
    if (! self.mapView) {
        return;
    }
    float height = ([options objectForKey:@"height"]) ? [[options objectForKey:@"height"] floatValue] : self.mapView.frame.size.height;
    float width = ([options objectForKey:@"width"]) ? [[options objectForKey:@"width"] floatValue] : self.mapView.frame.size.width;
    float x = ([options objectForKey:@"x"]) ? [[options objectForKey:@"x"] floatValue] : self.mapView.frame.origin.x;
    float y = ([options objectForKey:@"y"]) ? [[options objectForKey:@"y"] floatValue] : self.mapView.frame.origin.y;

    [self.mapView setFrame:CGRectMake(x, y, width, height)];
}

- (void)createViewWithOptions:(NSDictionary *)options {

    //This is the Designated Initializer

    // defaults
    int height = ([options objectForKey:@"height"]) ? [[options objectForKey:@"height"] intValue] : self.webView.bounds.size.height;
    int width = ([options objectForKey:@"width"]) ? [[options objectForKey:@"width"] intValue] : self.webView.bounds.size.width;
    int x = ([options objectForKey:@"x"]) ? [[options objectForKey:@"x"] intValue] : self.webView.bounds.origin.x;
    int y = ([options objectForKey:@"y"]) ? [[options objectForKey:@"y"] intValue] : self.webView.bounds.origin.y;
    int cornerRadius = ([options objectForKey:@"borderRadius"]) ? [[options objectForKey:@"borderRadius"] intValue] : 0;
    int bottom = ([options objectForKey:@"bottom"]) ? [[options objectForKey:@"bottom"] intValue] : 0;

    float latitude = ([options objectForKey:@"lat"]) ? [[options objectForKey:@"lat"] floatValue] : 0;
    float longitude = ([options objectForKey:@"lon"]) ? [[options objectForKey:@"lon"] floatValue] : 0;
    float latitudeDelta = ([options objectForKey:@"latDelta"]) ? [[options objectForKey:@"latDelta"] floatValue] : 0.2;
    float longitudeDelta = ([options objectForKey:@"lonDelta"]) ? [[options objectForKey:@"lonDelta"] floatValue] : 0.2;

    if (bottom > 0) {
        height -= bottom;
    }

    self.childView = [[UIView alloc] initWithFrame:CGRectMake(x,y,width,height)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(self.childView.bounds.origin.x, self.childView.bounds.origin.x, self.childView.bounds.size.width, self.childView.bounds.size.height)];
    self.mapView.delegate = self;
    self.mapView.layer.cornerRadius = cornerRadius;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
  self.mapView.showsUserLocation = YES;
    self.mapView.clipsToBounds = YES;
  self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    CLLocationCoordinate2D centerCoord = { latitude, longitude };
    MKCoordinateSpan delta = { latitudeDelta, longitudeDelta };
  MKCoordinateRegion region =[ self.mapView regionThatFits: MKCoordinateRegionMake(centerCoord, delta)];
    [self.mapView setRegion:region animated:YES];
  [self.childView addSubview:self.mapView];

  [ [ [ self viewController ] view ] addSubview:self.childView];

}

-(void) buttonClicked:(id)sender
{
    NSLog(@"you clicked on button %@", sender);
}

- (void)destroyMap:(CDVInvokedUrlCommand *)command
{
  if (self.mapView)
  {
    [ self.mapView removeAnnotations:mapView.annotations];
    [ self.mapView removeFromSuperview];

    mapView = nil;
  }
  if(self.imageButton)
  {
    [ self.imageButton removeFromSuperview];
    //[ self.imageButton removeTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
    self.imageButton = nil;

  }
  if(self.childView)
  {
    [ self.childView removeFromSuperview];
    self.childView = nil;
  }
    self.buttonCallback = nil;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];

}

- (void)clearMapPins:(CDVInvokedUrlCommand *)command
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)move:(CDVInvokedUrlCommand *)command
{
    if (self.mapView)
  {
        [self reConfigureViewWithOptions:command.arguments[0]];
  }
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)addMapPins:(CDVInvokedUrlCommand *)command
{

    NSArray *pins = command.arguments[0];

  for (int y = 0; y < pins.count; y++)
    {
        NSDictionary *pinData = [pins objectAtIndex:y];
    CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
    NSString *title=[[pinData valueForKey:@"title"] description];
    NSString *subTitle=[[pinData valueForKey:@"snippet"] description];
    NSInteger index=[[pinData valueForKey:@"index"] integerValue];
    BOOL selected = [[pinData valueForKey:@"selected"] boolValue];

        NSString *pinColor = nil;

        if([[pinData valueForKey:@"icon"] isKindOfClass:[NSNumber class]])
        {
            pinColor = [[pinData valueForKey:@"icon"] description];
        }
        else if([[pinData valueForKey:@"icon"] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *iconOptions = [pinData valueForKey:@"icon"];
            pinColor = [[iconOptions valueForKey:@"pinColor" ] description];
        }

    CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle];
    annotation.pinColor=pinColor;
    annotation.selected = selected;

    [self.mapView addAnnotation:annotation];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
  }

}

-(void)showMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView)
  {
        [self createViewWithOptions:command.arguments[0]];
  }

  self.childView.hidden = NO;
  self.mapView.showsUserLocation = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


- (void)hideMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
  {
    return;
  }
  // disable location services, if we no longer need it.
  self.mapView.showsUserLocation = NO;
  self.childView.hidden = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

/*
- (void)getUserLocation:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    double lat = mapView.userLocation.coordinate.latitude;
    double lon = mapView.userLocation.coordinate.longitude;
    NSDictionary *location = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:lat] , @"lat",
                                [NSNumber numberWithFloat:lon], @"lon", nil];

    if (!self.mapView)
  {
    return;
  }
    if (true) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:location];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
*/

- (void)setLocation:(CDVInvokedUrlCommand *)command
{

    NSDictionary *options = [[NSDictionary alloc] init];
    MKCoordinateRegion mapRegion;

    options = command.arguments[0];

    if (!self.mapView)
  {
    return;
  }

    float latitude = ([options objectForKey:@"lat"]) ? [[options objectForKey:@"lat"] floatValue] : 0;
    float longitude = ([options objectForKey:@"lon"]) ? [[options objectForKey:@"lon"] floatValue] : 0;
    float latitudeDelta = ([options objectForKey:@"latDelta"]) ? [[options objectForKey:@"latDelta"] floatValue] : 0.2;
    float longitudeDelta = ([options objectForKey:@"lonDelta"]) ? [[options objectForKey:@"lonDelta"] floatValue] : 0.2;

    mapRegion.center.latitude = latitude;
    mapRegion.center.longitude = longitude;
    mapRegion.span.latitudeDelta = latitudeDelta;
    mapRegion.span.longitudeDelta = longitudeDelta;

    [self.mapView setRegion:mapRegion animated: YES];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


- (void)reverseGeocode:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [[NSDictionary alloc] init];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    options = command.arguments[0];

    float latitude = ([options objectForKey:@"lat"]) ? [[options objectForKey:@"lat"] floatValue] : 0;
    float longitude = ([options objectForKey:@"lon"]) ? [[options objectForKey:@"lon"] floatValue] : 0;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];

    [geocoder reverseGeocodeLocation:location
        completionHandler:^(NSArray *placemarks, NSError *error) {
            CDVPluginResult* pluginResult = nil;
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            } else {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:placemark.addressDictionary];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    ];
}

- (void)changeMapType:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
  {
    return;
  }

    int mapType = ([command.arguments[0] objectForKey:@"mapType"]) ? [[command.arguments[0] objectForKey:@"mapType"] intValue] : 0;

    switch (mapType) {
        case 4:
            [self.mapView setMapType:MKMapTypeHybrid];
            break;
        case 2:
            [self.mapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [self.mapView setMapType:MKMapTypeStandard];
            break;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

/*
- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    float currentLat = userLocation.coordinate.latitude;
    float currentLon = userLocation.coordinate.longitude;

    NSString* jsData = [[NSString alloc] initWithFormat:@"{ lat: '%f', lon: '%f' }", currentLat,currentLon];

    [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('userlocationchange', %@);", jsData]];
}
*/

- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated
{
    float currentLat = theMapView.region.center.latitude;
    float currentLon = theMapView.region.center.longitude;
    float latitudeDelta = theMapView.region.span.latitudeDelta;
    float longitudeDelta = theMapView.region.span.longitudeDelta;

    NSString* jsData = [[NSString alloc] initWithFormat:@"{ location: { lat: '%f', lon: '%f' }, delta: { lat: '%f', lon: '%f' } }", currentLat,currentLon,latitudeDelta,longitudeDelta];

    [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('mapmove', %@);", jsData]];
}

- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation {

  if ([annotation class] != CDVAnnotation.class) {
    return nil;
  }

  CDVAnnotation *phAnnotation=(CDVAnnotation *) annotation;
  NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];

  MKPinAnnotationView *annView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];

  if (annView!=nil) return annView;

  annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];

  annView.animatesDrop=YES;
  annView.canShowCallout = YES;
  if ([phAnnotation.pinColor isEqualToString:@"120"])
    annView.pinColor = MKPinAnnotationColorGreen;
  else if ([phAnnotation.pinColor isEqualToString:@"270"])
    annView.pinColor = MKPinAnnotationColorPurple;
  else
    annView.pinColor = MKPinAnnotationColorRed;

  if (phAnnotation.index!=-1)
  {
    UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    myDetailButton.frame = CGRectMake(0, 0, 23, 23);
    myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    annView.rightCalloutAccessoryView = myDetailButton;
  }

  if(phAnnotation.selected)
  {
    [self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
  }

  return annView;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        [ self openGoogleMapsApp:view.annotation ];
    } else {
        [ self openAppleMapsApp:view.annotation ];
    }
}

-(void) openAppleMapsApp:(id <MKAnnotation>) annotation {
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
    {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:annotation.coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:annotation.title];
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking};
        MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
        [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
    }
}

-(void) openGoogleMapsApp:(id <MKAnnotation>) annotation {
    NSString *coordinateString = [[NSString alloc] initWithFormat:@"%f,%f", annotation.coordinate.latitude, annotation.coordinate.longitude];
    NSString *googleUrl = [[NSString alloc] initWithFormat:@"comgooglemaps://?daddr=%@&directionsmode=walking&views=transit", coordinateString];

    [[UIApplication sharedApplication] openURL:
     [NSURL URLWithString:googleUrl]];
}

-(void)openAnnotation:(id <MKAnnotation>) annotation
{
  [ self.mapView selectAnnotation:annotation animated:YES];
}

- (void)dealloc
{
    if (self.mapView)
  {
    [ self.mapView removeAnnotations:mapView.annotations];
    [ self.mapView removeFromSuperview];
        self.mapView = nil;
  }
  if(self.imageButton)
  {
    [ self.imageButton removeFromSuperview];
        self.imageButton = nil;
  }
  if(childView)
  {
    [ self.childView removeFromSuperview];
        self.childView = nil;
  }
    self.buttonCallback = nil;
}

@end