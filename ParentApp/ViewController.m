//
//  ViewController.m
//  ParentApp
//
//  Created by Vladyslav Gusakov on 1/22/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <CLLocationManagerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UITextField *userNameText;
@property (weak, nonatomic) IBOutlet UITextField *latitudeText;
@property (weak, nonatomic) IBOutlet UITextField *longitudeText;
@property (weak, nonatomic) IBOutlet UITextField *radiusText;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSMutableDictionary *userDetails;
@property (strong, nonatomic) NSDictionary *userUpdateDict;
@property (weak, nonatomic) IBOutlet UILabel *childStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *createUserButton;
@property (weak, nonatomic) IBOutlet UIButton *updateUserButton;
@property (weak, nonatomic) IBOutlet UIButton *getChildStatusButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

- (void) ConvertDictionaryToJSONAndMakeRequest: (NSString *) str;
- (IBAction)createUserButtonClicked:(id)sender;
- (IBAction)getChildStatusButtonClicked:(id)sender;
- (IBAction)updateUserButtonClicked:(id)sender;

@end

@implementation ViewController

NSString *jsonString;
NSData *jsonData;
CLLocationCoordinate2D coordinate;
NSDictionary *jsonToDict;
//NSURLConnection *conn;
NSURLSession *session;
NSURLSessionDataTask *childTask;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userNameText.delegate = self;
    self.latitudeText.delegate = self;
    self.longitudeText.delegate = self;
    self.radiusText.delegate = self;
    
    UIImage *backgroundImage = [UIImage imageNamed:@"back_4.png"];
    
    backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeTile];
    
    self.backgroundImageView.image = backgroundImage;
    

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    
    NSURLRequest *imgRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.staffsprep.com/software/flat_faces_icons/png/flat_faces_icons_circle/flat-faces-icons-circle-17.png"]];
    
    session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:imgRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSLog(@"Error occurred: %@", error.localizedDescription);
            }];
        }
        else
        {
            UIImage *image = [[UIImage alloc] initWithData:data];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.imageView.image = image;
            }];
        }
        
    }];
    
    [task resume];
    
}

- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(nonnull CLLocation *)newLocation fromLocation:(nonnull CLLocation *)oldLocation {
    CLLocation *currentLocation = newLocation;
    NSLog(@"%@", currentLocation);
    
    coordinate = [newLocation coordinate];
    NSLog(@"latitude:%@", [NSString stringWithFormat:@"%f", coordinate.latitude]);
    NSLog(@"longitude:%@", [NSString stringWithFormat:@"%f", coordinate.longitude]);
    self.latitudeText.text = [NSString stringWithFormat:@"%f", coordinate.latitude];
    self.longitudeText.text = [NSString stringWithFormat:@"%f", coordinate.longitude];
    NSLog(@"location updated");
    
}

- (IBAction)createUserButtonClicked:(id)sender {
    
    [self ConvertDictionaryToJSONAndMakeRequest:@"Create User"];

}

- (IBAction)getChildStatusButtonClicked:(id)sender {

    NSString *jsonAddress = [NSString stringWithFormat:@"http://protected-wildwood-8664.herokuapp.com/users/%@.json", [self.userNameText.text lowercaseString]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:jsonAddress]];
    
    childTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *dataReceived = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"Data: %@", dataReceived);
        
        jsonToDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSNumber *result = jsonToDict[@"is_in_zone"];
        NSLog(@"In zone?%@", result);
        
        NSNumber *inZone = jsonToDict[@"is_in_zone"];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.radiusText.text = [NSString stringWithFormat:@"%@",jsonToDict[@"radius"]];
            
            if ([inZone boolValue] == true) {
                self.childStatusLabel.text = @"in zone";
                
            }
            else {
                self.childStatusLabel.text = @"not in zone";
            }
        }];
        
    }];
    
    [childTask resume];
    
}

- (IBAction)updateUserButtonClicked:(id)sender {
    
    [self ConvertDictionaryToJSONAndMakeRequest:@"Update User"];
    
}


- (void) ConvertDictionaryToJSONAndMakeRequest: (NSString *) str {
    
    BOOL isUpdate = ([str  isEqual: @"Update User"])? true: false;

    
    self.userDetails = [NSMutableDictionary
                        dictionaryWithDictionary:
                        @{    @"utf8": @"✓",
                              @"authenticity_token": @"EvZva3cKnzo3Y0G5R3NktucCr99o/2UWOPVAmJYdBOc=",
                              @"user":
                                  @{@"username": self.userNameText.text,
                                    @"latitude": self.latitudeText.text,
                                    @"longitude": self.longitudeText.text,
                                    @"radius": self.radiusText.text
                                    },
                              @"commit":str,
                              @"action":@"update",
                              @"controller":@"users"
                              }];
    
    NSError *error;
    jsonData = [NSJSONSerialization dataWithJSONObject:self.userDetails
                                               options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                 error:&error];
    
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", jsonString);
        
    }
    
    
    NSURL *url = [NSURL URLWithString:@"http://protected-wildwood-8664.herokuapp.com/users/"];
    
    if (isUpdate == true) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://protected-wildwood-8664.herokuapp.com/users/%@", [self.userNameText.text lowercaseString]]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    if (isUpdate == true) {
        [request setHTTPMethod:@"PATCH"];
    }
    else
        [request setHTTPMethod:@"POST"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%@", jsonString] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: jsonData];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
    
    [self.locationManager stopUpdatingLocation];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return TRUE;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
