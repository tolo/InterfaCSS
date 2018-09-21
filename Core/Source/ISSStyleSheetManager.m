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
#import "ISSStyleSheetParserSyntax.h"
#import "ISSPropertyManager.h"

#import "ISSStyleSheet.h"
#import "ISSRuleset.h"
#import "ISSSelector.h"
#import "ISSPseudoClass.h"
#import "ISSStylingContext.h"
#import "ISSElementStylingProxy.h"

#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSAdditions.h"
#import "NSArray+ISSAdditions.h"


@interface ISSStyleSheetManager ()

@property (nonatomic, strong) NSMutableArray* styleSheets;
@property (nonatomic, readonly) NSArray* activeStylesheets;

@property (nonatomic, strong) NSMutableDictionary* runtimeStyleSheetsVariables;

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

        _styleSheetParser = parser ?: [[ISSStyleSheetParser alloc] init];
        _styleSheetParser.styleSheetManager = self;

        _styleSheets = [NSMutableArray array];

        _runtimeStyleSheetsVariables = [NSMutableDictionary dictionary];
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


- (ISSStyleSheet*) loadStyleSheetFromLocalFileURL:(NSURL*)styleSheetFile withName:(NSString*)name group:(NSString*)groupName {
    ISSStyleSheet* styleSheet = nil;
    
    for(ISSStyleSheet* existingStyleSheet in self.styleSheets) {
        if( [existingStyleSheet.styleSheetURL isEqual:styleSheetFile] ) {
            ISSLogDebug(@"Stylesheet %@ already loaded", styleSheetFile);
            return existingStyleSheet;
        }
    }
    
    NSError* error = nil;
    NSString* styleSheetData = [NSString stringWithContentsOfURL:styleSheetFile usedEncoding:nil error:&error];
    
    if( styleSheetData ) {
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        ISSStyleSheetContent* styleSheetContent = [self.styleSheetParser parse:styleSheetData];
        ISSLogDebug(@"Loaded stylesheet '%@' in %f seconds", [styleSheetFile lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));
        
        if( styleSheetContent ) {
            styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetFile name:name group:groupName content:styleSheetContent];
            [self.styleSheets addObject:styleSheet];

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
        return [self loadStyleSheetFromLocalFileURL:url withName:name group:groupName];
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
        return [self loadStyleSheetFromLocalFileURL:[NSURL fileURLWithPath:styleSheetFilePath] withName:name group:groupName];
    } else {
        ISSLogWarning(@"Unable to load stylesheet '%@' - file not found!", styleSheetFilePath);
        return nil;
    }
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetURL {
    return [self loadRefreshableNamedStyleSheet:nil group:nil fromURL:styleSheetURL];
}

- (ISSStyleSheet*) loadRefreshableNamedStyleSheet:(NSString*)name group:(NSString*)groupName fromURL:(NSURL*)styleSheetURL {
    ISSRefreshableStyleSheet* styleSheet = [[ISSRefreshableStyleSheet alloc] initWithStyleSheetURL:styleSheetURL name:name group:groupName content:nil];
    [self.styleSheets addObject:styleSheet];
    [self reloadRefreshableStyleSheet:styleSheet force:NO];
    
    BOOL usingStyleSheetModificationMonitoring = NO;
    if( styleSheet.styleSheetModificationMonitoringSupported ) { // Attempt to use file monitoring instead of polling, if supported
        __weak ISSStyleSheetManager* weakSelf = self;
        [styleSheet startMonitoringStyleSheetModification:^(ISSRefreshableStyleSheet* refreshed) {
            [weakSelf reloadRefreshableStyleSheet:styleSheet force:YES];
        }];
        usingStyleSheetModificationMonitoring = styleSheet.styleSheetModificationMonitoringEnabled;
    }

    if( !usingStyleSheetModificationMonitoring ) {
        [self enableAutoRefreshTimer];
    }
    
    return styleSheet;
}


- (void) reloadRefreshableStyleSheets:(BOOL)force {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSWillRefreshStyleSheetsNotification object:nil];
    
    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        ISSRefreshableStyleSheet* refreshableStylesheet = [styleSheet isKindOfClass: ISSRefreshableStyleSheet.class] ? (ISSRefreshableStyleSheet*)styleSheet : nil;
        if( refreshableStylesheet.active && !refreshableStylesheet.styleSheetModificationMonitoringEnabled ) { // Attempt to get updated stylesheet
            [self doReloadRefreshableStyleSheet:refreshableStylesheet force:force];
        }
    }
}

- (void) reloadRefreshableStyleSheet:(ISSRefreshableStyleSheet*)styleSheet force:(BOOL)force {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSWillRefreshStyleSheetsNotification object:styleSheet];
    
    [self doReloadRefreshableStyleSheet:styleSheet force:force];
}

- (void) doReloadRefreshableStyleSheet:(ISSRefreshableStyleSheet*)styleSheet force:(BOOL)force {
    [styleSheet refreshStylesheetWith:self andCompletionHandler:^{
        [self.styleSheets removeObject:styleSheet];
        [self.styleSheets addObject:styleSheet]; // Make stylesheet "last added/updated"
        [[NSNotificationCenter defaultCenter] postNotificationName:ISSDidRefreshStyleSheetNotification object:styleSheet];
    } force:force];
}

- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling {
    [self.styleSheets removeObject:styleSheet];
    [styleSheet unload];
    [self.stylingManager clearAllCachedStyles];
}

- (void) unloadAllStyleSheets:(BOOL)refreshStyling {
    [self.styleSheets removeAllObjects];
    [self.stylingManager clearAllCachedStyles];
}

- (NSArray*) activeStylesheets {
    return [self.styleSheets iss_filter:^BOOL(ISSStyleSheet* styleSheet) {
        return styleSheet.active;
    }];
}



- (ISSRulesets*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    NSMutableArray* rulesets = [[NSMutableArray alloc] init];
    
    for (ISSStyleSheet* styleSheet in self.activeStylesheets) {
        // Find all matching (or potentially matching, i.e. pseudo class) rulesets
        ISSRulesets* styleSheetRulesets = [styleSheet rulesetsMatchingElement:elementDetails stylingContext:stylingContext];
        if ( styleSheetRulesets ) {
            for(ISSRuleset* ruleset in styleSheetRulesets) {
                // Get reference to inherited rulesets, if any:
                if ( ruleset.extendedDeclarationSelectorChain && !ruleset.extendedDeclaration ) {
                    for (ISSStyleSheet* s in self.activeStylesheets) {
                        ruleset.extendedDeclaration = [s findPropertyDeclarationsWithSelectorChain:ruleset.extendedDeclarationSelectorChain];
                        if (ruleset.extendedDeclaration) break;
                    }
                }
            }
            [rulesets addObjectsFromArray:styleSheetRulesets];
        }
    }
    
    return [rulesets copy];
}



#pragma mark - Variables

- (NSString*) valueOfStyleSheetVariableWithName:(NSString*)variableName {
    NSString* value = self.runtimeStyleSheetsVariables[variableName];
    if( value == nil ) {
        for (ISSStyleSheet* styleSheet in [self.activeStylesheets reverseObjectEnumerator]) {
            value = styleSheet.content.variables[variableName];
            if( value != nil ) break;
        }
    }
    return value;
}

- (void) setValue:(NSString*)value forStyleSheetVariableWithName:(NSString*)variableName {
    self.runtimeStyleSheetsVariables[variableName] = value;
}

- (NSString*) replaceVariableReferences:(NSString*)propertyValue didReplace:(BOOL*)didReplace {
    NSUInteger location = 0;

    while( location < propertyValue.length ) {
        // Replace any variable references
        NSRange atRange = [propertyValue rangeOfString:@"@" options:0 range:NSMakeRange(location, propertyValue.length - location)];
        if( atRange.location != NSNotFound ) {
            location = atRange.location + atRange.length;

            // @ found, get variable name
            NSRange variableNameRange = NSMakeRange(location, 0);
            for(NSUInteger i=location; i<propertyValue.length; i++) {
                if( [[ISSStyleSheetParserSyntax shared].validIdentifierCharsSet characterIsMember:[propertyValue characterAtIndex:i]] ) {
                    variableNameRange.length++;
                } else break;
            }

            id variableValue = nil;
            id variableName = nil;
            if( variableNameRange.length > 0 ) {
                variableName = [propertyValue substringWithRange:variableNameRange];
                variableValue = [self valueOfStyleSheetVariableWithName:variableName];
            }
            if( variableValue ) {
                variableValue = [variableValue iss_trimQuotes];
                variableValue = [self replaceVariableReferences:variableValue didReplace:didReplace]; // Resolve nested variables

                // Replace variable occurrence in propertyValue string with variableValue string
                propertyValue = [propertyValue stringByReplacingCharactersInRange:NSMakeRange(atRange.location, variableNameRange.length+1)
                                                                       withString:variableValue];
                location += [variableValue length];

                if( didReplace ) *didReplace = YES;
            } else {
                ISSLogWarning(@"Unrecognized property variable: %@ (property value: %@)", variableName, propertyValue);
                location += variableNameRange.length;
            }
        } else break;
    }

    return propertyValue;
}

- (id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName asPropertyType:(ISSPropertyType)propertyType {
    NSString* value = [self valueOfStyleSheetVariableWithName:variableName];
    if( value ) value = [self replaceVariableReferences:value didReplace:NULL];
    if( value ) return [self.styleSheetParser parsePropertyValue:value asType:propertyType];
    else return nil;
}

- (id) parsePropertyValue:(NSString*)value asType:(ISSPropertyType)type didReplaceVariableReferences:(BOOL*)didReplace {
    value = [self replaceVariableReferences:value didReplace:didReplace];
    return [self.styleSheetParser parsePropertyValue:value asType:type];
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

- (void) logMatchingRulesetsForElement:(ISSElementStylingProxy*)element styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    NSString* objectIdentity = [NSString stringWithFormat:@"<%@: %p>", [element.uiElement class], (__bridge void*)element.uiElement];
    
    NSMutableSet* existingSelectorChains = [[NSMutableSet alloc] init];
    BOOL match = NO;
    ISSStylingContext* stylingContext = [[ISSStylingContext alloc] initWithStylingManager:self.stylingManager styleSheetScope:styleSheetScope];
    for (ISSStyleSheet* styleSheet in self.activeStylesheets) {
        ISSRulesets* matchingDeclarations = [[styleSheet rulesetsMatchingElement:element stylingContext:stylingContext] mutableCopy];
        NSMutableArray* descriptions = [NSMutableArray array];
        if( matchingDeclarations.count ) {
            [matchingDeclarations enumerateObjectsUsingBlock:^(id ruleset, NSUInteger idx1, BOOL *stop1) {
                NSMutableArray* chainsCopy = [((ISSRuleset*)ruleset).selectorChains mutableCopy];
                [chainsCopy enumerateObjectsUsingBlock:^(id chainObj, NSUInteger idx2, BOOL *stop2) {
                    if( [existingSelectorChains containsObject:chainObj] ) chainsCopy[idx2] =  [NSString stringWithFormat:@"%@ (WARNING - DUPLICATE)", [chainObj displayDescription]];
                    else chainsCopy[idx2] = [chainObj displayDescription];
                    [existingSelectorChains addObject:chainObj];
                }];
                
                [descriptions addObject:[NSString stringWithFormat:@"%@ {...}", [chainsCopy componentsJoinedByString:@", "]]];
            }];
            
            NSLog(@"Rulesets in '%@' matching %@: [\n\t%@\n]", styleSheet.styleSheetURL.lastPathComponent, objectIdentity, [descriptions componentsJoinedByString:@", \n\t"]);
            match = YES;
        }
    }
    if( !match ) NSLog(@"No rulesets match %@", objectIdentity);
}

@end
