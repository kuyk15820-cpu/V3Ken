#import "RootViewController.h"
#import <ffmpegkit/FFmpegKit.h>
#import <PhotosUI/PhotosUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "obfuscate.h"

@interface RootViewController () <UITableViewDelegate, UITableViewDataSource, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, assign) float currentScale;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation RootViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait; 
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ตั้งค่าพื้นหลังรวมเป็นสีดำสนิทสนมกับ Dark Mode 
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.currentScale = 2.0f; // ค่าเริ่มต้นของ itsscale
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        // --- เปลี่ยนเป็นสไตล์ Large Title ของระบบ iOS ---
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        self.title = [NSString stringWithUTF8String:AY_OBFUSCATE("TT-Tool")];
        
        // --- เพิ่มปุ่ม Info ขวาบน ของระบบ ---
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [infoButton addTarget:self action:@selector(infoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *infoItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
        self.navigationItem.rightBarButtonItem = infoItem;
        // -------------------------------------------------------------------
    }

    [self setupData];
    [self setupTableView];
    [self setupSpinner];
}

// Action เมื่อผู้ใช้แตะปุ่ม Info ขวาบน
- (void)infoButtonTapped {
    [self showStatusAlert:[NSString stringWithUTF8String:AY_OBFUSCATE("TT-Tool Version 1.0\nDeveloped with security protection.")]];
}

- (void)setupData {
    self.menuItems = @[
        @{
            @"title": [NSString stringWithUTF8String:AY_OBFUSCATE("เลือกวิดีโอจากคลังภาพ")], 
            @"subtitle": [NSString stringWithUTF8String:AY_OBFUSCATE("ระบบจะยืดเวลาวิดีโอให้เล่นช้าลง 2 เท่า")]
        }
    ];
}

- (void)setupTableView {
    // โครงสร้างเป็น Plain แท้ 100% เพื่อให้ Header ลอยค้าง (Sticky) ได้ตามระบบ
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    
    // ซ่อนเส้นคั่นตารางเดิมของระบบออกไป (เหมือน .listRowSeparator(.hidden))
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.tableView];
}

- (void)setupSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spinner.color = [UIColor whiteColor];
    self.spinner.center = self.view.center;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
}

#pragma mark - UITableView Quick Setup (Dark Style)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

// กำหนดความสูงของ Header เพื่อให้มีช่องไฟด้านบนสวยงาม
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

// ปรับแต่งหน้าตา Header Plain ให้ดูสวยและเยื้องเข้าขอบจอ
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor systemBackgroundColor]; // พื้นหลังเบลนด์เข้ากับจอ
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, tableView.bounds.size.width - 32, 30)];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor secondaryLabelColor];
    
    if (section == 0) {
        label.text = [[NSString stringWithUTF8String:AY_OBFUSCATE("เครื่องมือจัดการวิดีโอ")] uppercaseString];
    }
    
    [headerView addSubview:label];
    return headerView;
}

// ลบวิธีเก่าออกเพื่อไม่ให้ซ้อนทับกัน
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PlatterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // สร้างถาดรอง (Platter View) ประจำตัว Cell
    UIView *platterView = nil;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        
        // ทำให้ตัวเนื้อ Cell จริงๆ โปร่งใส เพื่อโชว์แผ่นข้างหลัง
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        
        cell.textLabel.textColor = [UIColor labelColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        
        cell.selectedBackgroundView = nil;
        
        // --- ส่วนการสร้าง Custom Section Platter (ถาดรองสีเทาเข้มหรูหราขอบมน) ---
        platterView = [[UIView alloc] init];
        platterView.tag = 999; // กำหนดแท็กไว้เรียกหาตอนอัปเดตขนาด
        platterView.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        platterView.layer.cornerRadius = 12.0f; // ความโค้งมนสไตล์ iOS
        platterView.layer.masksToBounds = YES;
        
        // แทรกแผ่นถาดรองไว้ด้านหลังตัวหนังสือทั้งหมด
        [cell.contentView insertSubview:platterView atIndex:0];
    } else {
        platterView = [cell.contentView viewWithTag:999];
    }
    
    // คำนวณขนาดและบีบขอบซ้ายขวา (Margin) ให้แผ่น Platter ดูลอยแยกจากขอบจอเสมือน Inset Grouped
    CGFloat margin = 16.0f;
    platterView.frame = CGRectMake(margin, 4, tableView.bounds.size.width - (margin * 2), 64 - 8);
    platterView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    NSDictionary *item = self.menuItems[indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = item[@"subtitle"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // ใส่ไอคอน SF Symbols เข้าไปที่ด้านซ้ายของ Cell
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:[NSString stringWithUTF8String:AY_OBFUSCATE("video.badge.plus")]];
        cell.imageView.tintColor = [UIColor whiteColor];
    }
    
    return cell;
}

// กำหนดความสูงมาตรฐานให้พอดีกับขนาดถาดรอง
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0f;
}

// ขยับตัวหนังสือด้านในให้อยู่ในขอบเขตของแผ่น Platter สวยงาม
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.separatorInset = UIEdgeInsetsMake(0, 32, 0, 32);
    // ดันเนื้อหาขยับเข้ามาด้านในเล็กน้อยเพื่อให้ไม่ติดขอบถาดรองเกินไป
    cell.contentView.bounds = CGRectMake(-8, 0, cell.contentView.bounds.size.width, cell.contentView.bounds.size.height);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        [self openSystemPicker];
    }
}

#pragma mark - Core Action: ดึงไฟล์ดิบผ่าน PHPicker (เลี่ยง WebKit Auto-Compress)

- (void)openSystemPicker {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    config.filter = [PHPickerFilter videosFilter];
    config.preferredAssetRepresentationMode = PHPickerConfigurationAssetRepresentationModeCurrent; // จุดสำคัญ: ดึงไฟล์ดิบ ไม่แปลงไฟล์!
    
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (results.count == 0) return;
    
    [self.spinner startAnimating];
    
    PHPickerResult *result = results.firstObject;
    NSItemProvider *provider = result.itemProvider;
    
    // ดึง Type Identifier ของไฟล์วิดีโอต้นฉบับ
    NSString *typeIdentifier = [NSString stringWithUTF8String:AY_OBFUSCATE("public.mpeg-4")];
    if (![provider hasItemConformingToTypeIdentifier:typeIdentifier]) {
        if (provider.registeredTypeIdentifiers.count > 0) {
            typeIdentifier = provider.registeredTypeIdentifiers.firstObject;
        }
    }
    
    [provider loadFileRepresentationForTypeIdentifier:typeIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (error || !url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                [self showStatusAlert:[NSString stringWithUTF8String:AY_OBFUSCATE("เกิดข้อผิดพลาดในการดึงไฟล์")]];
            });
            return;
        }
        
        // กำหนดเส้นทางไปยัง Documents/.F1X3R/
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *customDirPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:AY_OBFUSCATE(".F1X3R")]];
        [[NSFileManager defaultManager] createDirectoryAtPath:customDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        // สร้างชื่อไฟล์ตามวันที่และเวลา
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithUTF8String:AY_OBFUSCATE("dd-MM-yyyy-HH:mm")]];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        NSString *outputFileName = [NSString stringWithFormat:[NSString stringWithUTF8String:AY_OBFUSCATE("%@.MP4")], dateString];
        
        NSString *inputPath = [customDirPath stringByAppendingPathComponent:[NSString stringWithUTF8String:AY_OBFUSCATE("Input.MP4")]];
        NSString *outputPath = [customDirPath stringByAppendingPathComponent:outputFileName];
        
        [[NSFileManager defaultManager] removeItemAtPath:inputPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:inputPath error:nil];
        
        // ประกอบคำสั่งและเริ่มประมวลผลผ่านคลัง FFmpegKit โดยใช้ความเร็วคงที่ 2.0
        NSString *cmd = [NSString stringWithFormat:[NSString stringWithUTF8String:AY_OBFUSCATE("-itsscale 2.0 -i %@ -codec copy %@")], inputPath, outputPath];
        
        [FFmpegKit executeAsync:cmd withCompleteCallback:^(id<Session> session) {
            ReturnCode *code = [session getReturnCode];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                if ([ReturnCode isSuccess:code]) {
                    // ส่งวิดีโอผลลัพธ์กลับเข้าไปบันทึกไว้ในม้วนฟิล์มคลังภาพ
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:outputPath]];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        
                        // ลบไฟล์ทิ้งทั้งหมดเมื่อทำการบันทึกลงคลังแล้ว
                        [[NSFileManager defaultManager] removeItemAtPath:inputPath error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (success) {
                                [self showStatusAlert:[NSString stringWithUTF8String:AY_OBFUSCATE("Success")]];
                            } else {
                                [self showStatusAlert:[NSString stringWithUTF8String:AY_OBFUSCATE("Saved successfully, but could not be saved to the album; access to the photo library has been revoked.")]];
                            }
                        });
                    }];
                } else {
                    // ลบไฟล์ทิ้งกรณีประมวลผลล้มเหลว
                    [[NSFileManager defaultManager] removeItemAtPath:inputPath error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
                    
                    [self showStatusAlert:[NSString stringWithUTF8String:AY_OBFUSCATE("คำสั่งทำงานล้มเหลว")]];
                }
            });
        }];
    }];
}

- (void)showStatusAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithUTF8String:AY_OBFUSCATE("ระบบทำงาน")] message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithUTF8String:AY_OBFUSCATE("ตกลง")] style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
