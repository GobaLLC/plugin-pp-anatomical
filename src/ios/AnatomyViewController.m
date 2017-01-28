//
//  AnatomyViewController.m
//  Hello
//
//  Created by Grayson Sharpe on 1/18/17.
//
//

#import "AnatomyViewController.h"
#import "NSOperationQueue+Completion.h"
#import "AnatomyImage.h"
#import "MBProgressHUD.h"
#import "NSArray+Addition.h"
#import "NSDictionary+Addition.h"

@interface AnatomyViewController ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UISlider *frameSlider;
@property (weak, nonatomic) IBOutlet UISlider *layerSlider;

@property (strong, nonatomic) NSString* fileName;
@property (strong, nonatomic) NSString* folderName;
@property (strong, nonatomic) NSString* imagePath;
@property (strong, nonatomic) NSString* folderPath;

@property (strong, nonatomic) NSMutableArray *maleAnatomyImages;
@property (strong, nonatomic) NSMutableArray *femaleAnatomyImages;

@property (assign, nonatomic) int currentFrame;
@property (assign, nonatomic) int currentLayer;
@property (assign, nonatomic) float currentLayerValue;

@property (assign, nonatomic) int totalMaleLayers;
@property (assign, nonatomic) int totalAnglesPerMaleLayer;

@property (assign, nonatomic) int totalFemaleLayers;
@property (assign, nonatomic) int totalAnglesPerFemaleLayer;


@property (assign, nonatomic) float numberOfImagesLoaded;
@property (assign, nonatomic) float totalImagesToDownload;


@end

@implementation AnatomyViewController

NSString * const kLayersKey = @"aLayers";
NSString * const kMaleAngleKey = @"aAngles1";
NSString * const kFemaleAngleKey = @"aAngles2";
NSString * const kImageResolution = @"20";
NSString * const kImageName = @"image.jpg";


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI_2);
    _layerSlider.transform = trans;
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];    
    [self.navigationItem setLeftBarButtonItem:menuItem];
    
    self.maleAnatomyImages = [[NSMutableArray alloc] init];
    self.femaleAnatomyImages = [[NSMutableArray alloc] init];
    
    self.folderName = @"mBrain";
    self.fileName = @"m_brain";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.folderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.folderName];
    
    
    _currentLayer = 1;
    _currentFrame = 1;
    
    //    http://s3.amazonaws.com/goba_dev/y8yIRUIUcynOjK/iyjyusqDMofjt3/Angle/10/m_brain_L03_17.jpg
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    _hud.label.text = @"Loading...";
    
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:[_jsonDataString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    [self parseAnatomyData: jsonData];
    
    
    self.totalImagesToDownload = self.maleAnatomyImages.count + self.femaleAnatomyImages.count;
    
    NSMutableArray *anatomyImagesToDownload = [NSMutableArray array];
    [anatomyImagesToDownload addObjectsFromArray:self.maleAnatomyImages];
    [anatomyImagesToDownload addObjectsFromArray:self.femaleAnatomyImages];
    [self downloadImagesToDisk:anatomyImagesToDownload];
}

- (IBAction)dismiss:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)parseAnatomyData:(NSDictionary*)json {
    self.totalMaleLayers = 0;
    self.totalAnglesPerMaleLayer = 0;
    
    self.totalFemaleLayers = 0;
    self.totalAnglesPerFemaleLayer = 0;
    
    
    int layerIndex = 0;
    NSArray *aLayers = [json objectForKey:kLayersKey or:nil];
    if([aLayers count] == 0){
        NSLog(@"ERROR: Critical error has occurred. No Data is present.");
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"There is no layer data available for this model." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    
    for(NSDictionary *layerObj in aLayers){
        NSString *layerFolderName = [NSString stringWithFormat:@"%@/L%02d",_folderName, layerIndex];
        
        int angleIndex = 0;
        NSArray *aAngles1 = [layerObj objectForKey:kMaleAngleKey or:nil];
        if([aAngles1 count] == 0){
            NSLog(@"ERROR: No angle data is present at Male layer %d", layerIndex);
        }
        
        for(NSDictionary *angleObj in aAngles1){
            NSString *angleFolderName = [NSString stringWithFormat:@"%@/male/%02d", layerFolderName, angleIndex];
            NSDictionary *angleResolutionObj = [angleObj objectForKey:kImageResolution or:nil];
            AnatomyImage *anatomyImage = [[AnatomyImage alloc] initWithDictionary:angleResolutionObj folderPath:angleFolderName layerLevel:layerIndex angleNumber:angleIndex];
            [self.maleAnatomyImages addObject:anatomyImage];
            angleIndex++;
        }
        if(angleIndex > 0){
            if(_totalAnglesPerMaleLayer > 0)
                self.totalAnglesPerMaleLayer = MIN(_totalAnglesPerMaleLayer, angleIndex);
            else
                self.totalAnglesPerMaleLayer = angleIndex;
        }
        
        
        NSArray *aAngles2 = [layerObj objectForKey:@"aAngles2" or:nil];
        if([aAngles2 count] == 0){
            NSLog(@"ERROR: No angle data is present at Female layer %d", layerIndex);
        }
        
        angleIndex = 0;
        for(NSDictionary *angleObj in aAngles2){
            NSString *angleFolderName = [NSString stringWithFormat:@"%@/female/%02d", layerFolderName, angleIndex];
            NSDictionary *angleResolutionObj = [angleObj objectForKey:kImageResolution or:nil];
            AnatomyImage *anatomyImage = [[AnatomyImage alloc] initWithDictionary:angleResolutionObj folderPath:angleFolderName layerLevel:layerIndex angleNumber:angleIndex];
            [self.femaleAnatomyImages addObject:anatomyImage];
            angleIndex++;
        }
        if(angleIndex > 0){
            if(_totalAnglesPerFemaleLayer > 0)
                self.totalAnglesPerFemaleLayer = MIN(_totalAnglesPerFemaleLayer, angleIndex);
            else
                self.totalAnglesPerFemaleLayer = angleIndex;
        }
        
        //We'll just call this the top layer since there are no angle images here
        if(aAngles1.count == 0 && aAngles2.count == 0){
            break;
        }
        
        layerIndex++;
    }
    
    if(layerIndex > 0){
        if(_totalMaleLayers > 0)
            self.totalMaleLayers = MIN(_totalMaleLayers, layerIndex);
        else
            self.totalMaleLayers = layerIndex;
        
        if(_totalFemaleLayers > 0)
            self.totalFemaleLayers = MIN(_totalFemaleLayers, layerIndex);
        else
            self.totalFemaleLayers = layerIndex;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)downloadImagesToDisk:(NSArray*)anatomyImagesToDownload {
    NSOperationQueue *downloadQueue = [[NSOperationQueue alloc] init];
    downloadQueue.maxConcurrentOperationCount = 4;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    
    for(AnatomyImage *anatomyImage in anatomyImagesToDownload){
        NSURL *url = [NSURL URLWithString:anatomyImage.sourceUrl];
        
        NSString *imagePath = [docsPath stringByAppendingPathComponent:anatomyImage.folderPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:imagePath withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
        }
        
        NSString *path = [imagePath stringByAppendingPathComponent:kImageName];
        if (![fileManager fileExistsAtPath:path]) {
            [downloadQueue addOperationWithBlock:^{
                NSString *path = [imagePath stringByAppendingPathComponent:kImageName];
                NSData *data = [NSData dataWithContentsOfURL:url];
                if (data)
                    [data writeToFile:path atomically:YES];
                _numberOfImagesLoaded++;
                
                float progress = ((_numberOfImagesLoaded/_totalImagesToDownload) * 1.0f);
                NSLog(@"Progress: %f/%f = %f", _numberOfImagesLoaded, _totalImagesToDownload, progress);
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Instead we could have also passed a reference to the HUD
                    // to the HUD to myProgressTask as a method parameter.
                    _hud.progress = progress;
                });
            }];
        }
    }
    
    [downloadQueue setCompletion:^{
        NSLog(@"finished downloading files");
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
        
        NSLog(@"files array %@", filePathsArray);
        
        [self setupLevels];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_hud hideAnimated:YES];
        });
    }];
    
}

- (void)setupLevels{
    _layerSlider.minimumValue = 0.0f;
    _layerSlider.maximumValue = self.totalMaleLayers - 1;
    _layerSlider.value = 0.0f;
    
    _frameSlider.minimumValue = 0.0f;
    _frameSlider.maximumValue = self.totalAnglesPerMaleLayer;
    _frameSlider.value = 0.0f;
    
    for (int i=(_totalMaleLayers-1); i>=0; i--){
        [self addImageViewToLayer:i frameNum:0];
    }
}

- (void)addImageViewToLayer: (int)layerLevel frameNum: (int)frameNum {
    NSString *filePath = [@[_folderPath, [NSString stringWithFormat:@"L%02d", layerLevel], @"male", [NSString stringWithFormat:@"%02d", frameNum], kImageName] componentsJoinedByString:@"/"];
    
    CGRect frame = CGRectMake(0.0, 0.0, _containerView.frame.size.width, _containerView.frame.size.height - 200.0);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setClipsToBounds:YES];
    
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    [imageView setImage:image];
    [imageView setAlpha:1.0];
    [imageView setTag:(layerLevel+1)];
    [_containerView addSubview:imageView];
}

- (IBAction)frameSliderValueChanged:(id)sender {
    //    NSLog(@"slider value %f", _frameSlider.value);
    _currentFrame = (int)floor(_frameSlider.value);
    for (int i=(_totalMaleLayers-1); i>=0; i--){
        int visibleFrame;
        if(_currentFrame == _totalAnglesPerMaleLayer){
            visibleFrame = 0;
        }
        else{
            visibleFrame = _currentFrame;
        }
        
        NSString *filePath = [@[_folderPath, [NSString stringWithFormat:@"L%02d", i], @"male", [NSString stringWithFormat:@"%02d", visibleFrame], kImageName] componentsJoinedByString:@"/"];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        UIImageView *imageView = [self currentAnatomyImageViewWithIndex:i];
        [imageView setImage:image];
    }
}

- (IBAction)layerSliderValueChanged:(id)sender {
    _currentLayer = (int)floor(_layerSlider.value);
    
    if(_currentLayer != (_totalMaleLayers - 1)){
        int nextLayer = fmin(_currentLayer+1, _totalAnglesPerMaleLayer);
        UIImageView *currentImageView = [self currentAnatomyImageViewWithIndex:_currentLayer];
        currentImageView.alpha = nextLayer - _layerSlider.value;
    }
}

- (UIImageView*)currentAnatomyImageViewWithIndex:(NSInteger)index{
    return (UIImageView*)[self.containerView viewWithTag:(index+1)];
}

- (float)keepBetweenLow:(int)low hi:(int)hi num:(int)num {
    if (num < low) return (low);
    else if (num > hi) return (hi);
    else return (num);
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
