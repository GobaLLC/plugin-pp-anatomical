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

@interface AnatomyViewController ()<UIGestureRecognizerDelegate>{
    CGPoint _prevPoint;
    BOOL _showOneGender;
    
    int _totalMaleLayers;
    int _totalAnglesPerMaleLayer;
    int _currentMaleFrame;
    int _currentMaleLayer;
    float _currentMaleLayerValue;
    
    int _totalFemaleLayers;
    int _totalAnglesPerFemaleLayer;
    int _currentFemaleFrame;
    int _currentFemaleLayer;
    float _currentFemaleLayerValue;
    
    int _totalLayers;
    int _totalAngles;
    int _currentFrame;
    int _currentLayer;
    float _currentLayerValue;
    
    float _numberOfImagesLoaded;
    float _totalImagesToDownload;
    
    AnatomyGender _selectedGender;
}

@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *anatomyLabel;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *genderButton;

@property (strong, nonatomic) NSString* anatomyName;
@property (strong, nonatomic) NSString* anatomyIdentifier;
@property (strong, nonatomic) NSString* folderName;
@property (strong, nonatomic) NSString* imagePath;
@property (strong, nonatomic) NSString* folderPath;

@property (strong, nonatomic) NSMutableArray *maleAnatomyImages;
@property (strong, nonatomic) NSMutableArray *femaleAnatomyImages;

@property (strong, nonatomic) NSString* currentGender;
@property (strong, nonatomic) NSString* imageResolution;

@end

@implementation AnatomyViewController

NSString * const kLayersKey = @"aLayers";
NSString * const kAnglesKey = @"aAngles";
NSString * const kImageName = @"image.jpg";
float kFrameRotationTolerance = 7.0f;
float kLayerTransitionTolerance = 10.0f;


- (void)viewDidLoad {
    [super viewDidLoad];
    _prevPoint = self.containerView.center;
    
    _currentLayerValue = 0.0f;
    _currentLayer = 0;
    _currentFrame = 0;
    
    _selectedGender = AnatomyGenderFemale;
    
    NSLog(@"%f", [[UIScreen mainScreen] bounds].size.height);
    
    if([[UIScreen mainScreen] bounds].size.height > 568.0)
        self.imageResolution = @"30";
    else
        self.imageResolution = @"20";
    
    //    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI_2);
    //    _layerSlider.transform = trans;
    //    _layerSlider.hidden = YES;
    
    //_containerView.layer.borderWidth = 2.0f;
    //_containerView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateItem:)];
    _panGesture.delegate = self;
    [self.containerView addGestureRecognizer:_panGesture];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    //    [self.navigationItem setLeftBarButtonItem:menuItem];
    
    self.maleAnatomyImages = [[NSMutableArray alloc] init];
    self.femaleAnatomyImages = [[NSMutableArray alloc] init];
    
    self.anatomyName = [self.jsonData objectForKey:@"sTitle" or:nil];
    self.anatomyIdentifier = [NSString stringWithFormat:@"%d", [[self.jsonData objectForKey:@"nID" or:nil] intValue]];
    
    self.anatomyLabel.text = _anatomyName;
    
    self.folderName = _anatomyIdentifier;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.folderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.folderName];
    
    //    http://s3.amazonaws.com/goba_dev/y8yIRUIUcynOjK/iyjyusqDMofjt3/Angle/10/m_brain_L03_17.jpg
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    _hud.label.text = @"Loading...";
    
    [self parseAnatomyData: self.jsonData];
    
    _totalImagesToDownload = self.maleAnatomyImages.count + self.femaleAnatomyImages.count;
    
    NSMutableArray *anatomyImagesToDownload = [NSMutableArray array];
    [anatomyImagesToDownload addObjectsFromArray:self.maleAnatomyImages];
    [anatomyImagesToDownload addObjectsFromArray:self.femaleAnatomyImages];
    [self downloadImagesToDisk:anatomyImagesToDownload];
}

- (IBAction)dismiss:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)genderButtonPressed:(id)sender{
    if(_selectedGender == AnatomyGenderFemale){
        _selectedGender = AnatomyGenderMale;
        [_genderButton setImage:[UIImage imageNamed:@"icon_male"] forState:UIControlStateNormal];
    }
    else{
        _selectedGender = AnatomyGenderFemale;
        [_genderButton setImage:[UIImage imageNamed:@"icon_female"] forState:UIControlStateNormal];
    }
    
    [self setupLevels];
}

- (void)parseAnatomyData:(NSDictionary*)json {
    _totalMaleLayers = 0;
    _totalAnglesPerMaleLayer = 0;
    
    _totalFemaleLayers = 0;
    _totalAnglesPerFemaleLayer = 0;
    
    
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
        NSString *maleJsonKey = [NSString stringWithFormat:@"%@%d", kAnglesKey, AnatomyGenderMale];
        NSArray *aAngles1 = [layerObj objectForKey:maleJsonKey or:nil];
        if([aAngles1 count] == 0){
            NSLog(@"ERROR: No angle data is present at Male layer %d", layerIndex);
        }
        
        for(NSDictionary *angleObj in aAngles1){
            NSString *angleFolderName = [NSString stringWithFormat:@"%@/male/%02d", layerFolderName, angleIndex];
            NSDictionary *angleResolutionObj = [angleObj objectForKey:_imageResolution or:nil];
            AnatomyImage *anatomyImage = [[AnatomyImage alloc] initWithDictionary:angleResolutionObj folderPath:angleFolderName layerLevel:layerIndex angleNumber:angleIndex];
            [self.maleAnatomyImages addObject:anatomyImage];
            angleIndex++;
        }
        if(angleIndex > 0){
            if(_totalAnglesPerMaleLayer > 0)
                _totalAnglesPerMaleLayer = MIN(_totalAnglesPerMaleLayer, angleIndex);
            else
                _totalAnglesPerMaleLayer = angleIndex;
            
            _totalMaleLayers++;
        }
        
        NSString *femaleJsonKey = [NSString stringWithFormat:@"%@%d", kAnglesKey, AnatomyGenderFemale];
        NSArray *aAngles2 = [layerObj objectForKey:femaleJsonKey or:nil];
        if([aAngles2 count] == 0){
            NSLog(@"ERROR: No angle data is present at Female layer %d", layerIndex);
        }
        
        angleIndex = 0;
        for(NSDictionary *angleObj in aAngles2){
            NSString *angleFolderName = [NSString stringWithFormat:@"%@/female/%02d", layerFolderName, angleIndex];
            NSDictionary *angleResolutionObj = [angleObj objectForKey:_imageResolution or:nil];
            AnatomyImage *anatomyImage = [[AnatomyImage alloc] initWithDictionary:angleResolutionObj folderPath:angleFolderName layerLevel:layerIndex angleNumber:angleIndex];
            [self.femaleAnatomyImages addObject:anatomyImage];
            angleIndex++;
        }
        if(angleIndex > 0){
            if(_totalAnglesPerFemaleLayer > 0)
                _totalAnglesPerFemaleLayer = MIN(_totalAnglesPerFemaleLayer, angleIndex);
            else
                _totalAnglesPerFemaleLayer = angleIndex;
            
            _totalFemaleLayers++;
        }
        
        layerIndex++;
    }
}

- (void) rotateItem:(UIPanGestureRecognizer *)recognizer {
    CGFloat xTranslation = [recognizer translationInView:recognizer.view].x;
    CGFloat yTranslation = [recognizer translationInView:recognizer.view].y;
    
    if(fabs(xTranslation) >= kFrameRotationTolerance){
        CGFloat nextFrame = _currentFrame - (CGFloat)(xTranslation / kFrameRotationTolerance);
        [self updateAnatomyImageFrame:(int)nextFrame];
        
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
    
    if(fabs(yTranslation) >= kLayerTransitionTolerance){
        _currentLayerValue = _currentLayerValue + (CGFloat)((yTranslation / kLayerTransitionTolerance)*0.1);
        _currentLayerValue = fmax(_currentLayerValue, 0.0f);
        _currentLayerValue = fmin(_currentLayerValue, _totalLayers);
        _currentLayer = (int)floor(_currentLayerValue);
        
        if(_currentLayer != (_totalLayers - 1)){
            int nextLayer = fmin(_currentLayer+1, _totalAngles);
            UIImageView *currentImageView = [self currentAnatomyImageViewWithIndex:_currentLayer];
            float alpha = nextLayer - _currentLayerValue;
            currentImageView.alpha = alpha;
        }
        
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
}

- (BOOL) gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)recognizer {
    return YES;
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
                //                NSLog(@"Progress: %f/%f = %f", _numberOfImagesLoaded, _totalImagesToDownload, progress);
                dispatch_async(dispatch_get_main_queue(), ^{
                    _hud.progress = progress;
                });
            }];
        }
    }
    
    [downloadQueue setCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupLevels];
            [_hud hideAnimated:YES];
        });
    }];
    
}

- (void)setupLevels{
    //    _layerSlider.minimumValue = 0.0f;
    //    _layerSlider.maximumValue = self.totalMaleLayers - 1;
    //    _layerSlider.value = 0.0f;
    if((_totalMaleLayers == 0 && _totalFemaleLayers > 0) ||
       (_totalMaleLayers > 0 && _totalFemaleLayers == 0))
    {
        _showOneGender = YES;
        _genderButton.hidden = YES;
    }
    else{
        _showOneGender = NO;
        _genderButton.hidden = NO;
    }
    
    
    [[self.containerView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if(_selectedGender == AnatomyGenderMale){
        self.currentGender = @"male";
        _totalLayers = _totalMaleLayers;
        _totalAngles = _totalAnglesPerMaleLayer;
        
        _currentFemaleLayer = _currentLayer;
        _currentFemaleFrame = _currentFrame;
        _currentFemaleLayerValue = _currentLayerValue;
        
        _currentLayer = _currentMaleLayer;
        _currentFrame = _currentMaleFrame;
        _currentLayerValue = _currentMaleLayerValue;
    }
    else{
        self.currentGender = @"female";
        _totalLayers = _totalFemaleLayers;
        _totalAngles = _totalAnglesPerFemaleLayer;
        
        _currentMaleLayer = _currentLayer;
        _currentMaleFrame = _currentFrame;
        _currentMaleLayerValue = _currentLayerValue;
        
        _currentLayer = _currentFemaleLayer;
        _currentFrame = _currentFemaleFrame;
        _currentLayerValue = _currentFemaleLayerValue;
    }
    
    //     NSLog(@"currentLayer %d _currentLayerValue %f", _currentLayer, _currentLayerValue);
    
    _currentLayerValue = 0.0f;
    _currentLayer = 0;
    _currentFrame = 0;
    
    for (int i=(_totalLayers-1); i>=0; i--){
        [self addImageViewToLayer:i frameNum:_currentFrame];
    }
}

- (void)addImageViewToLayer: (int)layerLevel frameNum: (int)frameNum {
    int nextLayer = fmin(_currentLayer+1, _totalAngles);
    
    NSString *filePath = [@[_folderPath, [NSString stringWithFormat:@"L%02d", layerLevel], _currentGender, [NSString stringWithFormat:@"%02d", frameNum], kImageName] componentsJoinedByString:@"/"];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    CGRect frame = CGRectMake(10.0, 0.0, _containerView.frame.size.width - 20.0, _containerView.frame.size.width - 20.0);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setClipsToBounds:YES];
    [imageView setImage:image];
    [imageView setTag:(layerLevel+1)];
    if(_currentLayer == layerLevel){
        float alpha = nextLayer - _currentLayerValue;
        [imageView setAlpha:alpha];
    }
    else
        [imageView setAlpha:1.0];
    
    [_containerView addSubview:imageView];
}

- (void)updateAnatomyImageFrame:(int)nextFrame {
    
    for (int i=(_totalLayers-1); i>=0; i--){
        if(nextFrame >= _totalAngles)
            _currentFrame = 0;
        else if(nextFrame < 0)
            _currentFrame = _totalAngles-1;
        else
            _currentFrame = nextFrame;
        
        //        NSLog(@"current frame %d,   nextIndex: %d", _currentFrame, nextFrame);
        
        NSString *filePath = [@[_folderPath, [NSString stringWithFormat:@"L%02d", i], _currentGender, [NSString stringWithFormat:@"%02d", _currentFrame], kImageName] componentsJoinedByString:@"/"];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        UIImageView *imageView = [self currentAnatomyImageViewWithIndex:i];
        [imageView setImage:image];
    }
}

//- (IBAction)selectedGenderChanged:(id)sender {
//    [self setupLevels];
//}

- (UIImageView*)currentAnatomyImageViewWithIndex:(NSInteger)index{
    return (UIImageView*)[self.containerView viewWithTag:(index+1)];
}


@end
