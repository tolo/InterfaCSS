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
#import <InterfaCSS/ISSViewHierarchyParser.h>

@interface PrototypeExampleCell : UITableViewCell<ISSViewHierarchyFileOwner>
@property (nonatomic, strong) UILabel* label1;
@property (nonatomic, strong) UILabel* label2;
@property (nonatomic, strong) UILabel* label3;
@property (nonatomic, strong) NSMapTable *propertyTable;
@end


@implementation PrototypeExampleCell

- (void)viewHierarchyParserWillSetValue:(UIView *)view forKey:(NSString *)propertyName
{
    // keep record on all properties, even if there is no-ivar associated with it
    [self.propertyTable setObject:view forKey:propertyName];
}

- (NSMapTable *)propertyTable
{
    if (_propertyTable == nil) {
        _propertyTable = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _propertyTable;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    id value = [self.propertyTable objectForKey:key];
    if (value == nil) {
        value = [super valueForUndefinedKey:key];
    }
    return value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    [self.propertyTable setObject:value forKey:key];
}

@end



@interface PrototypeExampleViewController () <ISSViewHierarchyFileOwner>

@property (nonatomic, strong) UILabel* mainTitleLabel;
@property (nonatomic, strong) UIButton* mainTitleButton;

@property (nonatomic, strong) NSMapTable *propertyTable;

@end


@implementation PrototypeExampleViewController {
    NSArray* items;
}

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Prototype";
        
        self.propertyTable = [NSMapTable strongToWeakObjectsMapTable];
        
        items = @[
                  @{@"title":@"ágætis byrjun", @"subtitle": @"ágætis byrjun", @"year": @"1999"},
                    @{@"title":@"flugufrelsarinn", @"subtitle":@"ágætis byrjun", @"year":@"1999"},
                    @{@"title":@"olsen olsen", @"subtitle":@"ágætis byrjun", @"year":@"1999"},
                    @{@"title":@"starálfur", @"subtitle":@"ágætis byrjun", @"year":@"1999"},
                    @{@"title":@"svefn-g-englar", @"subtitle":@"ágætis byrjun", @"year":@"1999"},
                    @{@"title":@"popplagið", @"subtitle":@"", @"year":@"2002"},
                    @{@"title":@"samskeyti", @"subtitle":@"", @"year":@"2002"},
                    @{@"title":@"vaka", @"subtitle":@"", @"year":@"2002"},
                    @{@"title":@"glósóli", @"subtitle":@"takk", @"year":@"2005"},
                    @{@"title":@"hoppípolla", @"subtitle":@"takk", @"year":@"2005"},
                    @{@"title":@"ára bátur", @"subtitle":@"með suð í eyrum við spilum endalaust", @"year":@"2008"},
                    @{@"title":@"fljótavík", @"subtitle":@"með suð í eyrum við spilum endalaust", @"year":@"2008"},
                    @{@"title":@"ekki múkk", @"subtitle":@"Valtari", @"year":@"2012"},
                    @{@"title":@"varúð", @"subtitle":@"Valtari", @"year":@"2012"},
                    @{@"title":@"hrafntinna", @"subtitle":@"Kveikur", @"year":@"2013"},
                    @{@"title":@"ísjaki", @"subtitle":@"Kveikur", @"year":@"2013"},
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
    UITableViewCell *cell = [tableView dequeueReusablePrototypeCellWithIdentifierISS:@"prototypeExampleCell" forIndexPath:indexPath];
    
    NSDictionary* item = items[indexPath.row];

    for (NSString *key in item.keyEnumerator) {
        [[cell valueForKey:key] setText:item[key]];
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell applyStylingISS];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.selectedBackgroundView applyStylingWithAnimationISS];
}

#pragma mark ISSViewHierarchyFileOwner

- (void)viewHierarchyParserWillSetValue:(UIView *)view forKey:(NSString *)propertyName
{
    // keep record on all properties, even if there is no-ivar associated with it
    [self.propertyTable setObject:view forKey:propertyName];
}


@end
