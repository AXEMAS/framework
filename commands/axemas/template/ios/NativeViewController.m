//
//  NativeViewController.m
//  axemas
//
//  Created by Andrei Neagu on 30/10/14.
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import "NativeViewController.h"

@interface NativeViewController ()

@end

@implementation NativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)touchUpInsideButton:(id)sender {
    NSString* message =[NSString stringWithFormat:@"Device info\n%@",[[UIDevice currentDevice]name]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iOS native"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
