//
//  KSYStreamerVC+Rotation.m
//  KSYLiveDemo
//
//  Created by iVermisseDich on 2017/4/28.
//  Copyright © 2017年 qyvideo. All rights reserved.
//

#import "KSYStreamerVC+Rotation.h"

@implementation KSYStreamerVC (Rotation)

#pragma mark - ui rotate
- (void) onViewRotate { // 重写父类的方法, 参考父类 KSYUIView.m 中对UI旋转的响应
    [self layoutUI];
    if (self.kit == nil || !self.ksyFilterView.swUiRotate.on) {
        return;
    }
    if (self.ksyFilterView.swStrRotate.on) {
        // 1. 旋转推流方向
        UIInterfaceOrientation orie = [[UIApplication sharedApplication] statusBarOrientation];
        [self.kit rotateStreamTo:orie];
        
        // 2. 旋转水印方向，并调整大小和位置（保持水印大小和位置不变）
        // 2.1 traitCollection不变时不需要更改logo和时间水印的大小和位置
        if (self.curCollection.verticalSizeClass == self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            return;
        }
        self.curCollection = self.traitCollection;
        
        // 2.2 设置 logoRect
        [self.kit setLogoRect:CGRectMake(self.kit.logoRect.origin.x, self.kit.logoRect.origin.y, self.kit.logoRect.size.height, self.kit.logoRect.size.width)];
        
        // 根据text相对于logo的布局来计算text的Y值(text出于logo正下方)
        CGFloat textY = (self.kit.textRect.origin.y - self.kit.logoRect.origin.y) / (self.kit.streamDimension.height / self.kit.streamDimension.width) + self.kit.logoRect.origin.y;
        // width 根据推流分辨率计算
        CGFloat textheight = self.kit.textRect.size.height / self.kit.streamDimension.height * self.kit.streamDimension.width;
        // 2.3 设置 textRect
        [self.kit setTextRect:CGRectMake(self.kit.textRect.origin.x,
                                         textY,
                                         self.kit.textRect.size.width,
                                         textheight)];
    }
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.kit.preview.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

#pragma mark - 旋转预览 iOS > 8.0
// 旋转处理，通过旋转bgView来做到画面相对手机静止不动
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        CGAffineTransform deltaTransform = coordinator.targetTransform;
        CGFloat deltaAngle = atan2f(deltaTransform.b, deltaTransform.a);
        
        CGFloat currentRotation = [[self.kit.preview.layer valueForKeyPath:@"transform.rotation.z"] floatValue];
        // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
        currentRotation += -1 * deltaAngle + 0.0001;
        [self.kit.preview.layer setValue:@(currentRotation) forKeyPath:@"transform.rotation.z"];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
        CGAffineTransform currentTransform = self.kit.preview.transform;
        currentTransform.a = round(currentTransform.a);
        currentTransform.b = round(currentTransform.b);
        currentTransform.c = round(currentTransform.c);
        currentTransform.d = round(currentTransform.d);
        self.kit.preview.transform = currentTransform;
    }];
}

- (BOOL)shouldAutorotate {
    if (self.ksyFilterView){
        return self.ksyFilterView.swUiRotate.on;
    }
    return NO;
}

@end
