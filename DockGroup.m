#import <AppKit/AppKit.h>
#import "DockAppController.h"
#import "DockGroup.h"
#import "DockIcon.h"

@implementation DockGroup

- (instancetype) init
{
    self = [super init]; 
    if (self)
      {
        // Register for string types to allow for dragging DockIcons
        [self registerForDraggedTypes:@[NSStringPboardType]];

        _dockWindow = nil;
        _defaultIcons = [NSArray arrayWithObjects:@"Workspace", @"Terminal", @"SystemPreferences", nil];
        _dockPosition = @"Bottom";
        _direction = @"Horizontal";
        _startX = 0;
        _startY = 0;
        _dockedIcons = [[NSMutableArray alloc] init];
        _iconSize = 64;
        _activeLight = 10;
        _padding = 16;
      }
    return self;
}

- (void) dealloc
{
    // Remove self as an observer to avoid memory leaks
    [[NSNotificationCenter defaultCenter] removeObserver:self]; 
}

- (CGFloat) calculateDockWidth
{
    CGFloat dockWidth = [_dockedIcons count] * self.iconSize;
    return dockWidth;
}

- (void) updateFrame
{
    // Adjust the width
    CGFloat dockWidth = [self calculateDockWidth];
    NSSize currentContentSize = [self frame].size;
   
    NSSize newContentSize = [_direction isEqualToString:@"Horizontal"] ? NSMakeSize(dockWidth, self.iconSize) : NSMakeSize(self.iconSize, dockWidth);
    NSRect currentFrame = [self frame]; 
    NSRect newFrame = NSMakeRect(currentFrame.origin.x, 0, newContentSize.width, newContentSize.height);

    [self setFrame:newFrame];
}

- (void) updateIconPositions:(NSUInteger)startIndex
                  expandDock:(BOOL)isExpanding
{
    // If isDocked, we need to move subset of dockedIcons and all of the undockedIcons so we create a global array.
    // Otherwise we move subset of undockedIcons only.
    NSMutableArray *targetArray = nil;
    for (int i = startIndex; i < [self.dockedIcons count]; i++)
      {
        DockIcon *dockIcon = [self.dockedIcons objectAtIndex:i];
        NSRect currentFrame = [dockIcon frame];
  
        // Horizontal adjustments
        if([_dockPosition isEqualToString:@"Bottom"]) {
          CGFloat startX = currentFrame.origin.x;
  
          if(isExpanding){
            CGFloat expandedX = currentFrame.origin.x + _iconSize;          
            NSRect expandedFrame = NSMakeRect(expandedX, currentFrame.origin.y , self.iconSize, self.iconSize);
            [dockIcon setFrame:expandedFrame]; // Replace with tween
          } else {
            CGFloat contractedX = currentFrame.origin.x - _iconSize;
            NSRect contractedFrame = NSMakeRect(contractedX, currentFrame.origin.y , self.iconSize, self.iconSize);
            [dockIcon setFrame:contractedFrame]; // Replace with tween
          } 
  
        }
      }   
}

- (DockIcon *) addIcon:(NSString *)appName
             withImage:(NSImage *)iconImage
{
    // TODO: Animation Logic
    // NSMutableArray *iconsArray = _dockedIcons;
    DockIcon *dockIcon = [self generateIcon:appName withImage:iconImage];
    [self.dockedIcons addObject:dockIcon];
    [self addSubview:dockIcon];
    [self updateFrame];

    return dockIcon;
}

- (void) removeIcon:(NSString *)appName
{
    // TODO: Animation Logic
    NSMutableArray *iconsArray = self.dockedIcons;
    NSUInteger index = [self indexOfIcon:appName];
    NSLog(@"DockGroup: About to remove %@", appName);
    if (index != NSNotFound)
      { 
        // NSLog(@"RemoveIcon Method: Removing %@", appName);
        DockIcon *undockedIcon = [iconsArray objectAtIndex:index];
        [undockedIcon selfDestruct];
        [iconsArray removeObjectIdenticalTo:undockedIcon];
        // Update Undocked Icons
        [self updateIconPositions:index expandDock:NO];
      } else {
        NSLog(@"Error: Either not found or out of range. Could not remove %@", appName);
      }
}

- (BOOL) hasIcon:(NSString *)appName
{
    BOOL defaultValue = NO;
    NSUInteger index = [self indexOfIcon:appName];

    if(index != NSNotFound)
      {
        NSLog(@"DockGroup HASICON:%@ ", appName);
        return YES;
      } else {
        return defaultValue;
      }
}

- (NSUInteger) indexOfIcon:(NSString *)appName
{ 
    NSUInteger index = [self.dockedIcons indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        // 'obj' is the current object in the array 
        DockIcon *dockIcon = (DockIcon *)obj;
        
        return [[dockIcon getAppName] isEqualToString:appName];
    }];

    return index;
}

- (DockIcon *) getIconByName:(NSString *)appName
{ 
    NSMutableArray *iconsArray = _dockedIcons;
    NSUInteger index = [self indexOfIcon:appName];
    
    if (index != NSNotFound)
      {
        return [iconsArray objectAtIndex: index];
      } else {
        NSLog(@"getIconByName Method: index not found for %@", appName);
        NSLog(@"getIconByName Method: iconsArray count is %lu",(unsigned long)[iconsArray count]);
        return nil;
      }
}

- (void) setIconActive:(NSString *)appName
{
  DockIcon *dockIcon = [self.dockedIcons objectAtIndex:[self indexOfIcon:appName]];
  [dockIcon setActiveLightVisibility:YES];
}

- (void) setIconTerminated:(NSString *)appName
{
  DockIcon *dockIcon = [self.dockedIcons objectAtIndex:[self indexOfIcon:appName]];
  [dockIcon setActiveLightVisibility:NO];
}


- (NSRect) generateLocation:(NSString *)dockPosition
                    atIndex:(CGFloat) index
{
    if([dockPosition isEqualToString:@"Left"])
      {
        NSRect leftLocation = NSMakeRect(self.activeLight, [self.dockedIcons count] * self.iconSize + (self.padding), self.iconSize, self.iconSize);
        return leftLocation;
      } else if([dockPosition isEqualToString:@"Right"]) {
        NSRect rightLocation = NSMakeRect(self.activeLight, [self.dockedIcons count] * self.iconSize + (self.padding), self.iconSize, self.iconSize);
        return rightLocation;
      } else {
        // If unset we default to "Bottom"      
        NSRect bottomLocation = NSMakeRect(index * self.iconSize, self.activeLight, self.iconSize, self.iconSize);     
        return bottomLocation;
      }
}

- (DockIcon *) generateIcon:(NSString *)appName
                  withImage:(NSImage *)iconImage
{
    CGFloat iconCount = [self.dockedIcons count];
    NSRect location = [self generateLocation:_dockPosition atIndex:iconCount]; 
    DockIcon *iconButton = [[DockIcon alloc] initWithFrame:location];
    [iconButton setImage:iconImage];
    [iconButton setAppName:appName];
    [iconButton setBordered:NO];

    return iconButton;
}

// Events
- (NSMutableArray *)listIconNames
{ 
    NSMutableArray *appNames = [NSMutableArray array];

    for (int i = 0; i < [_dockedIcons count]; i++) {
        DockIcon *dockIcon = [_dockedIcons objectAtIndex:i];
        NSString *appName = [dockIcon getAppName];
        [appNames addObject:appName];
    }
    return appNames;
}


// Drag and drop stuff
// Handle dragging entered into the DockGroup
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        return NSDragOperationMove; // Allow moving the DockIcon within the DockGroup
    }
    return NSDragOperationNone;
}

// Perform the drop operation
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSString *droppedAppName = [pasteboard stringForType:NSStringPboardType];
    
    if (droppedAppName) {
        NSLog(@"Dropped icon: %@", droppedAppName);
        // Reorder or move the DockIcon as needed
        DockIcon *icon = [self getIconByName:droppedAppName];
        
        if (icon) {
            // Handle the reordering of the icon here, if necessary
            [self updateIconPositions:[self indexOfIcon:droppedAppName] expandDock:NO];
        }
        return YES;
    }
    return NO;
}

// Provide feedback as the dragging session progresses
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return NSDragOperationMove;
}
@end
