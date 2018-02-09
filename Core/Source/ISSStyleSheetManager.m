//
//  ISSStyleSheetManager.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSStyleSheetManager.h"

#import "ISSStylingManager.h"
#import "ISSStyleSheetParser.h"
#import "ISSPropertyManager.h"

#import "ISSStyleSheet.h"
#import "ISSRuleset.h"
#import "ISSSelector.h"
#import "ISSPseudoClass.h"
#import "ISSStylingContext.h"
#import "ISSElementStylingProxy.h"

#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSAdditions.h"


@interface ISSStyleSheetManager ()

@property (nonatomic, strong) NSMutableArray* styleSheets;
@property (nonatomic, readonly) NSArray* effectiveStylesheets;

@property (nonatomic, strong) NSMutableDictionary* styleSheetsVariables;

@property (nonatomic, strong) NSSet<ISSPseudoClassType>* pseudoClassTypes;

@property (nonatomic, strong) NSTimer* timer;

@end


@implementation ISSStyleSheetManager

- (instancetype) init {
    return [self initWithStyleSheetParser:nil];
}

- (instancetype) initWithStyleSheetParser:(ISSStyleSheetParser*)parser {
    if ( self = [super init] ) {
        _pseudoClassTypes = [NSSet setWithArray:@[
                #if TARGET_OS_TV == 0
                  ISSPseudoClassTypeInterfaceOrientationLandscape,
                  ISSPseudoClassTypeInterfaceOrientationLandscapeLeft,
                  ISSPseudoClassTypeInterfaceOrientationLandscapeRight,
                  ISSPseudoClassTypeInterfaceOrientationPortrait,
                  ISSPseudoClassTypeInterfaceOrientationPortraitUpright,
                  ISSPseudoClassTypeInterfaceOrientationPortraitUpsideDown,
                #endif
                  ISSPseudoClassTypeUserInterfaceIdiomPad,
                  ISSPseudoClassTypeUserInterfaceIdiomPhone,
                #if TARGET_OS_TV == 1
                  ISSPseudoClassTypeUserInterfaceIdiomTV,
                #endif
                  ISSPseudoClassTypeMinOSVersion,
                  ISSPseudoClassTypeMaxOSVersion,
                  ISSPseudoClassTypeDeviceModel,
                  ISSPseudoClassTypeScreenWidth,
                  ISSPseudoClassTypeScreenWidthLessThan,
                  ISSPseudoClassTypeScreenWidthGreaterThan,
                  ISSPseudoClassTypeScreenHeight,
                  ISSPseudoClassTypeScreenHeightLessThan,
                  ISSPseudoClassTypeScreenHeightGreaterThan,
              
                #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
                  ISSPseudoClassTypeHorizontalSizeClassRegular,
                  ISSPseudoClassTypeHorizontalSizeClassCompact,
                  ISSPseudoClassTypeVerticalSizeClassRegular,
                  ISSPseudoClassTypeVerticalSizeClassCompact,
                #endif
                  ISSPseudoClassTypeStateEnabled,
                  ISSPseudoClassTypeStateDisabled,
                  ISSPseudoClassTypeStateSelected,
                  ISSPseudoClassTypeStateHighlighted,

                  ISSPseudoClassTypeRoot,
                  ISSPseudoClassTypeNthChild,
                  ISSPseudoClassTypeNthLastChild,
                  ISSPseudoClassTypeOnlyChild,
                  ISSPseudoClassTypeFirstChild,
                  ISSPseudoClassTypeLastChild,
                  ISSPseudoClassTypeNthOfType,
                  ISSPseudoClassTypeNthLastOfType,
                  ISSPseudoClassTypeOnlyOfType,
                  ISSPseudoClassTypeFirstOfType,
                  ISSPseudoClassTypeLastOfType,
                  ISSPseudoClassTypeEmpty
        ]];
        
        _styleSheetsVariables = [NSMutableDictionary dictionary];
        
        _styleSheetParser = parser ?: [[ISSStyleSheetParser alloc] init];
        _styleSheetParser.styleSheetManager = self;
    }
    return self;
}


#pragma mark - Properties

- (void) setStylesheetAutoRefreshInterval:(NSTimeInterval)stylesheetAutoRefreshInterval {
    _stylesheetAutoRefreshInterval = stylesheetAutoRefreshInterval;
    if( _timer ) {
        [self disableAutoRefreshTimer];
        [self enableAutoRefreshTimer];
    }
}


#pragma mark - Timer

- (void) enableAutoRefreshTimer {
    if( !_timer && self.stylesheetAutoRefreshInterval > 0 ) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.stylesheetAutoRefreshInterval target:self selector:@selector(autoRefreshTimerTick) userInfo:nil repeats:YES];
    }
}

- (void) disableAutoRefreshTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void) autoRefreshTimerTick {
    [self reloadRefreshableStyleSheets:NO];
}


#pragma mark - Stylesheets

//- (void) refreshStylingForStyleSheet:(ISSStyleSheet*)styleSheet {
//    if( styleSheet.scope ) [self.stylingManager refreshStylingForScope:styleSheet.scope];
//    else [self.stylingManager refreshStyling];
//}

//- (ISSStyleSheet*) loadStyleSheetFromFileURL:(NSURL*)styleSheetFile withScope:(ISSStyleSheetScope*)scope {
- (ISSStyleSheet*) loadStyleSheetFromFileURL:(NSURL*)styleSheetFile withName:(NSString*)name group:(NSString*)groupName {
    ISSStyleSheet* styleSheet = nil;
    
    for(ISSStyleSheet* existingStyleSheet in self.styleSheets) {
        if( [existingStyleSheet.styleSheetURL isEqual:styleSheetFile] ) {
            ISSLogDebug(@"Stylesheet %@ already loaded", styleSheetFile);
//            if( scope ) existingStyleSheet.scope = scope;
            return existingStyleSheet;
        }
    }
    
    NSError* error = nil;
    NSString* styleSheetData = [NSString stringWithContentsOfURL:styleSheetFile usedEncoding:nil error:&error];
    
    if( styleSheetData ) {
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        NSMutableArray* declarations = [self.styleSheetParser parse:styleSheetData];
        ISSLogDebug(@"Loaded stylesheet '%@' in %f seconds", [styleSheetFile lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));
        
        if( declarations ) {
            styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetFile name:name group:groupName declarations:declarations refreshable:NO];
            [self.styleSheets addObject:styleSheet];
            
//            [self refreshStylingForStyleSheet:styleSheet];
            [self.stylingManager clearAllCachedStyles];
        }
    } else {
        ISSLogWarning(@"Error loading stylesheet data from '%@' - %@", styleSheetFile, error);
    }
    
    return styleSheet;
}

- (ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName {
    return [self loadNamedStyleSheet:nil group:nil fromMainBundleFile:styleSheetFileName];
}

- (ISSStyleSheet*) loadNamedStyleSheet:(NSString*)name group:(NSString*)groupName fromMainBundleFile:(NSString*)styleSheetFileName {
    NSURL* url = [[NSBundle mainBundle] URLForResource:styleSheetFileName withExtension:nil];
    if( url ) {
        return [self loadStyleSheetFromFileURL:url withName:name group:groupName];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found in main bundle!", styleSheetFileName);
        return nil;
    }
}

- (ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath {
    return [self loadNamedStyleSheet:nil group:nil fromFile:styleSheetFilePath];
}

- (nullable ISSStyleSheet*) loadNamedStyleSheet:(nullable NSString*)name group:(nullable NSString*)groupName fromFile:(NSString*)styleSheetFilePath {
    if( [[NSFileManager defaultManager] fileExistsAtPath:styleSheetFilePath] ) {
        return [self loadStyleSheetFromFileURL:[NSURL fileURLWithPath:styleSheetFilePath] withName:name group:groupName];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found!", styleSheetFilePath);
        return nil;
    }
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetURL {
    return [self loadRefreshableNamedStyleSheet:nil group:nil fromURL:styleSheetURL];
}

- (ISSStyleSheet*) loadRefreshableNamedStyleSheet:(NSString*)name group:(NSString*)groupName fromURL:(NSURL*)styleSheetURL {
    ISSStyleSheet* styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetURL name:name group:groupName declarations:nil refreshable:YES];
    [self.styleSheets addObject:styleSheet];
    [self reloadRefreshableStyleSheet:styleSheet force:NO];
    
    BOOL usingFileMonitoring = NO;
    if( styleSheetURL.isFileURL ) { // If local file URL - attempt to use file monitoring instead of polling
        __weak ISSStyleSheetManager* weakSelf = self;
        [styleSheet startMonitoringLocalFileChanges:^(ISSRefreshableResource* refreshed) {
            [weakSelf reloadRefreshableStyleSheet:styleSheet force:YES];
        }];
        usingFileMonitoring = styleSheet.usingLocalFileChangeMonitoring;
    }
    
    if( !usingFileMonitoring ) {
        [self enableAutoRefreshTimer];
    }
    
    return styleSheet;
}


- (void) reloadRefreshableStyleSheets:(BOOL)force {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSWillRefreshStyleSheetsNotification object:nil];
    
    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        if( styleSheet.refreshable && styleSheet.active && !styleSheet.usingLocalFileChangeMonitoring ) { // Attempt to get updated stylesheet
            [self doReloadRefreshableStyleSheet:styleSheet force:force];
        }
    }
}

- (void) reloadRefreshableStyleSheet:(ISSStyleSheet*)styleSheet force:(BOOL)force {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSWillRefreshStyleSheetsNotification object:styleSheet];
    
    [self doReloadRefreshableStyleSheet:styleSheet force:force];
}

- (void) doReloadRefreshableStyleSheet:(ISSStyleSheet*)styleSheet force:(BOOL)force {
    [styleSheet refreshStylesheetWith:self andCompletionHandler:^{
//        [self refreshStylingForStyleSheet:styleSheet];
        [[NSNotificationCenter defaultCenter] postNotificationName:ISSDidRefreshStyleSheetNotification object:styleSheet];
    } force:force];
}

- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling {
    [self.styleSheets removeObject:styleSheet];
    if( styleSheet.usingLocalFileChangeMonitoring ) {
        [styleSheet endMonitoringLocalFileChanges];
    }
//    if( refreshStyling ) [self refreshStylingForStyleSheet:styleSheet];
//    else
    [self.stylingManager clearAllCachedStyles];
}

- (void) unloadAllStyleSheets:(BOOL)refreshStyling {
    [self.styleSheets removeAllObjects];
//    if( refreshStyling ) [self.stylingManager refreshStyling];
//    else
    [self.stylingManager clearAllCachedStyles];
}

- (NSArray*) effectiveStylesheets {
    NSMutableArray* effective = [NSMutableArray array];
    NSMutableArray* refreshable = [NSMutableArray array];
    
    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        if( styleSheet.active ) {
            if( styleSheet.refreshable && self.processRefreshableStylesheetsLast ) {
                [refreshable addObject:styleSheet];
            } else {
                [effective addObject:styleSheet];
            }
        }
    }
    
    if( self.processRefreshableStylesheetsLast ) {
        [effective addObjectsFromArray:refreshable];
    }
    
    return effective;
}



- (NSArray<ISSRuleset*>*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    NSMutableArray* declarations = [[NSMutableArray alloc] init];
    
    for (ISSStyleSheet* styleSheet in self.effectiveStylesheets) {
        // Find all matching (or potentially matching, i.e. pseudo class) style declarations
        NSArray<ISSRuleset*>* styleSheetRulesets = [styleSheet rulesetsMatchingElement:elementDetails stylingContext:stylingContext];
        if ( styleSheetRulesets ) {
            for(ISSRuleset* ruleset in styleSheetRulesets) {
//                ruleset.scope = styleSheet.scope; // Hang on to the scope (for later reference)...
                
                // Get reference to inherited declarations, if any:
                if ( ruleset.extendedDeclarationSelectorChain && !ruleset.extendedDeclaration ) {
                    for (ISSStyleSheet* s in self.effectiveStylesheets) {
                        ruleset.extendedDeclaration = [s findPropertyDeclarationsWithSelectorChain:ruleset.extendedDeclarationSelectorChain];
                        if (ruleset.extendedDeclaration) break;
                    }
                }
            }
            [declarations addObjectsFromArray:styleSheetRulesets];
        }
    }
    
    return [declarations copy];
}


#pragma mark - Variables

- (NSString*) valueOfStyleSheetVariableWithName:(NSString*)variableName {
    return self.styleSheetsVariables[variableName];
}

- (id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName asPropertyType:(ISSPropertyType)propertyType {
    NSString* value = self.styleSheetsVariables[variableName];
    if( value ) return [self.styleSheetParser.propertyParser parsePropertyValue:value ofType:propertyType];
    else return nil;
}

- (void) setValue:(NSString*)value forStyleSheetVariableWithName:(NSString*)variableName {
    self.styleSheetsVariables[variableName] = value;
}


#pragma mark - Selector creation support

- (ISSSelector*) createSelectorWithType:(NSString*)type elementId:(NSString*)elementId styleClasses:(NSArray*)styleClasses pseudoClasses:(NSArray*)pseudoClasses {
    Class typeClass = nil;
    BOOL wildcardType = NO;
    
    if ( [type iss_hasData] ) {
        if ( [type isEqualToString:@"*"] ) {
            wildcardType = YES;
        } else {
            ISSPropertyManager* propertyManager = self.stylingManager.propertyManager;
            typeClass = [propertyManager canonicalTypeClassForType:type registerIfNotFound:YES];
        }
    }
    
    if ( wildcardType ) {
        return [[ISSSelector alloc] initWithWildcardTypeAndElementId:elementId styleClasses:styleClasses pseudoClasses:pseudoClasses];
    } else if ( typeClass || elementId || styleClasses.count ) {
        return [[ISSSelector alloc] initWithType:typeClass elementId:elementId styleClasses:styleClasses pseudoClasses:pseudoClasses];
    } else if ( [type iss_hasData] ) {
        ISSLogWarning(@"Unrecognized type: '%@' - Have you perhaps forgotten to register a valid type selector class?", type);
    } else {
        ISSLogWarning(@"Invalid selector - type and style class missing!");
    }
    return nil;
}


#pragma mark - Pseudo class customization support

- (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString {
    typeAsString = [typeAsString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return [_pseudoClassTypes member:[typeAsString lowercaseString]] ?: ISSPseudoClassTypeUnknown;
}

- (ISSPseudoClass*) createPseudoClassWithParameter:(NSString*)parameter type:(ISSPseudoClassType)type {
    return [[ISSPseudoClass alloc] initPseudoClassWithParameter:parameter type:type];
}


#pragma mark - Debugging support

- (void) logMatchingStyleDeclarationsForUIElement:(ISSElementStylingProxy*)elementDetails styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    NSString* objectIdentity = [NSString stringWithFormat:@"<%@: %p>", [elementDetails.uiElement class], (__bridge void*)elementDetails.uiElement];
    
    NSMutableSet* existingSelectorChains = [[NSMutableSet alloc] init];
    BOOL match = NO;
    ISSStylingContext* stylingContext = [[ISSStylingContext alloc] initWithStylingManager:self.stylingManager styleSheetScope:styleSheetScope];
    for (ISSStyleSheet* styleSheet in self.effectiveStylesheets) {
        NSArray<ISSRuleset*>* matchingDeclarations = [[styleSheet rulesetsMatchingElement:elementDetails stylingContext:stylingContext] mutableCopy];
        NSMutableArray* descriptions = [NSMutableArray array];
        if( matchingDeclarations.count ) {
            [matchingDeclarations enumerateObjectsUsingBlock:^(id declarationObj, NSUInteger idx1, BOOL *stop1) {
                NSMutableArray* chainsCopy = [((ISSRuleset*)declarationObj).selectorChains mutableCopy];
                [chainsCopy enumerateObjectsUsingBlock:^(id chainObj, NSUInteger idx2, BOOL *stop2) {
                    if( [existingSelectorChains containsObject:chainObj] ) chainsCopy[idx2] =  [NSString stringWithFormat:@"%@ (WARNING - DUPLICATE)", [chainObj displayDescription]];
                    else chainsCopy[idx2] = [chainObj displayDescription];
                    [existingSelectorChains addObject:chainObj];
                }];
                
                [descriptions addObject:[NSString stringWithFormat:@"%@ {...}", [chainsCopy componentsJoinedByString:@", "]]];
            }];
            
            NSLog(@"Declarations in '%@' matching %@: [\n\t%@\n]", styleSheet.styleSheetURL.lastPathComponent, objectIdentity, [descriptions componentsJoinedByString:@", \n\t"]);
            match = YES;
        }
    }
    if( !match ) NSLog(@"No declarations match %@", objectIdentity);
}

@end
