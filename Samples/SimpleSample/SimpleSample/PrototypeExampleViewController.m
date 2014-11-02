//
//  PrototypeExampleViewController.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-09.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "PrototypeExampleViewController.h"

#import <InterfaCSS.h>
#import <InterfaCSS/ISSViewBuilder.h>
#import <InterfaCSS/UITableView+InterfaCSS.h>
#import <InterfaCSS/UIView+InterfaCSS.h>


@interface PrototypeExampleCell : UITableViewCell
@property (nonatomic, strong) UILabel* label1;
@property (nonatomic, strong) UILabel* label3;
@end

@implementation PrototypeExampleCell
@end



@interface PrototypeExampleViewController ()

@property (nonatomic, strong) UILabel* mainTitleLabel;
@property (nonatomic, strong) UIButton* mainTitleButton;

@end


@implementation PrototypeExampleViewController {
    NSArray* items;
}

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Prototype";
        
        items = @[
                    @[@"ágætis byrjun", @"ágætis byrjun", @"1999"],
                    @[@"flugufrelsarinn", @"ágætis byrjun", @"1999"],
                    @[@"olsen olsen", @"ágætis byrjun", @"1999"],
                    @[@"starálfur", @"ágætis byrjun", @"1999"],
                    @[@"svefn-g-englar", @"ágætis byrjun", @"1999"],
                    @[@"popplagið", @"()", @"2002"],
                    @[@"samskeyti", @"()", @"2002"],
                    @[@"vaka", @"()", @"2002"],
                    @[@"glósóli", @"takk", @"2005"],
                    @[@"hoppípolla", @"takk", @"2005"],
                    @[@"ára bátur", @"með suð í eyrum við spilum endalaust", @"2008"],
                    @[@"fljótavík", @"með suð í eyrum við spilum endalaust", @"2008"],
                    @[@"ekki múkk", @"Valtari", @"2012"],
                    @[@"varúð", @"Valtari", @"2012"],
                    @[@"hrafntinna", @"Kveikur", @"2013"],
                    @[@"ísjaki", @"Kveikur", @"2013"],
                ];
    }
    return self;
}

- (void) loadView {
    // To prevent a lot of up front loading when application starts, loading of a stylesheet can be postponed until it's actually needed
    [[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"prototypeExample.css"];
    
    // Load the complete view hierachy for this view controller from the view definition file 'views.xml'
    self.view = [ISSViewBuilder loadViewHierarchyFromMainBundleFile:@"views.xml" withFileOwner:self];
    
    self.mainTitleLabel.text = @"Prototype Example";
    [self.mainTitleButton setTitle:@"Sample button" forState:UIControlStateNormal];
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Table View


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return items.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PrototypeExampleCell* cell = [tableView dequeueReusablePrototypeCellWithIdentifierISS:@"prototypeExampleCell" forIndexPath:indexPath];
    
    NSArray* item = items[indexPath.row];
    
    cell.label1.text = item[0];

    // Testing the use of an element Id for this label
    UILabel* label2 = [cell subviewWithElementId:@"label2"];
    label2.text = item[1];
    
    cell.label3.text = item[2];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell applyStylingISS];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.selectedBackgroundView applyStylingWithAnimationISS];
}

@end
