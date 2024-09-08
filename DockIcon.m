#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "DockIcon.h"
#import "ActiveLight.h"

@implementation DockIcon

NSPoint initialDragLocation;  // Declare instance variable inside @implementation

- (instancetype) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self)
      {
          _iconSize = 64;
          _iconImage = nil;
          _appName = @"Unknown";
          _showLabel = YES; // Change this to NO 
          _activeLight = nil; // Change this to NO
          _activeLightDiameter = 4.0;

          _isDragging = NO;
  
        [self setupDockIcon];
      }
    return self;
}

- (void) setupDockIcon
{
    // Do Stuff
    [super setToolTip:_appName];

    // Calculate the frame for the ActiveLight view
    NSRect bounds = [self bounds];
    // bounds.size.height += 4;

    // Calculate the x and y position to center the ActiveLight horizontally and place it at the bottom
    CGFloat xPosition = NSMidX(bounds) - (self.activeLightDiameter / 2.0);
    CGFloat yPosition = bounds.size.height - 4;  // Set a small margin from the bottom edge

    NSRect activeLightFrame = NSMakeRect(xPosition, yPosition, self.activeLightDiameter, self.activeLightDiameter);
    
    // Instantiate the ActiveLight view
    _activeLight = [[ActiveLight alloc] initWithFrame:activeLightFrame];
    [_activeLight setVisibility:NO];

    
    // Add ActiveLight as a subview to DockIcon
    [self addSubview:_activeLight];
};

- (void) setLabelVisibility:(BOOL) isVisible
{
  self.showLabel = isVisible;
}

- (void) setActiveLightVisibility:(BOOL)isVisible
{
    // Implement visibility toggle in ActiveLight Class
    // Toggle visibility of ActiveLight
    [self.activeLight setVisibility:isVisible];
}

- (NSString *) getAppName
{
  return _appName;
}

- (void) setAppName:(NSString *)name
{
    _appName = name;
    [super setToolTip:_appName]; 
}

- (NSImage *) getIconImage
{
  return _iconImage;
}

- (void) setIconImage:(NSImage *)iconImage
{
    _iconImage = iconImage;
    [self setNeedsDisplay:YES];
}

- (CGFloat) getIconSize
{
  return _iconSize;
}

- (void) setIconSize:(CGFloat)iconSize
{
  // We actually make ths icon size a little smaller to account for the activity light
  _iconSize = iconSize * 0.75;
  [self setNeedsDisplay:YES];
}

- (void) selfDestruct
{
    [self removeFromSuperview];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    if (self.iconImage && !_isDragging)
    {        
        NSSize fixedSize = NSMakeSize(self.iconSize, self.iconSize);

        // Calculate the position to center the image in the view
        NSRect bounds = self.bounds;
        CGFloat xPosition = (NSWidth(bounds) - fixedSize.width) / 2;
        CGFloat yPosition = (NSHeight(bounds) - fixedSize.height) / 2;
        NSRect imageRect = NSMakeRect(xPosition, yPosition, fixedSize.width, fixedSize.height);

        // Save the current graphics state
        [[NSGraphicsContext currentContext] saveGraphicsState];

        // Apply a vertical flip transformation to fix the upside-down image issue
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0 yBy:NSHeight(bounds)];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform concat];

        // Draw the iconImage within the fixed 64x64 rect
        [self.iconImage drawInRect:imageRect
                          fromRect:NSZeroRect
                         operation:NSCompositeSourceOver  // Use NSCompositeSourceOver for GNUstep
                          fraction:1.0];

        // Restore the previous graphics state
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
}


// Events
- (void)mouseDown:(NSEvent *)event {
    // [super mouseDown:event];
    NSLog(@"DockIcon MouseDown EVENT");
    // Capture the initial drag location (in window coordinates)
    initialDragLocation = [event locationInWindow];
}

- (void)mouseUp:(NSEvent *)event {
    // [super mouseUp:event];
    NSLog(@"DockIcon MouseUp EVENT");

    // Post a notification when DockIcon is clicked
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DockIconClickedNotification"
                                                        object:self
                                                      userInfo:@{@"appName": self.appName}];

}

- (void)mouseDragged:(NSEvent *)event
{ 
    NSLog(@"DockIcon MouseDragged EVENT");

    _isDragging = YES;

    // Prepare the pasteboard for dragging the DockIcon
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pasteboard declareTypes:@[NSStringPboardType] owner:self];
    
    // Set some identifier or app name for the dragged item
    [pasteboard setString:self.appName forType:NSStringPboardType];

    // Ensure that iconImage is set before dragging
    if (!self.iconImage) {
        NSLog(@"No iconImage set for DockIcon");
        return;
    }

    NSLog(@"DockIcon is Dragging...");

    NSPoint dragLocation = [event locationInWindow];
    
    /*
    // TODO: Decide if this custom drag behavior is how we should do things. Remove if the answer is no

    // Get the current icon image size
    NSSize imageSize = [self.iconImage size];

    // Create a temporary window for the drag, with the size of the icon image
    NSWindow *dragWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect([NSEvent mouseLocation].x, [NSEvent mouseLocation].y, imageSize.width, imageSize.height)
                                                       styleMask:NSWindowStyleMaskBorderless
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];

    [dragWindow setOpaque:NO];
    [dragWindow setBackgroundColor:[NSColor clearColor]];

    // Create an NSImageView to hold the icon image with its original size
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, imageSize.width, imageSize.height)];
    [imageView setImage:self.iconImage];

    [dragWindow.contentView addSubview:imageView];

    // Make the window visible
    [dragWindow makeKeyAndOrderFront:nil];

    // Move the window as the user drags the mouse
    while ([event type] != NSEventTypeLeftMouseUp) {
        // NSPoint newDragLocation = [event locationInWindow];
        NSPoint newDragLocation = [NSEvent mouseLocation];
        NSRect windowFrame = [dragWindow frame];
        windowFrame.origin.x = newDragLocation.x;
        windowFrame.origin.y = newDragLocation.y;
        [dragWindow setFrame:windowFrame display:YES];

        // Get the next event (match for left mouse dragging or mouse up)
        event = [[self window] nextEventMatchingMask:NSEventMaskFromType(NSEventTypeLeftMouseDragged) |
                                                    NSEventMaskFromType(NSEventTypeLeftMouseUp)];
    }

    // After the drag ends, remove the window
    [dragWindow close];*/


    // Without custom drag implementation
    // Convert the mouse location from window coordinates to the DockIcon's view coordinates
    NSPoint dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];

    // Create the drag image by calling the abstracted method
    NSImage *dragImage = [self drawImage:self.iconImage withSize:self.iconImage.size];

    // Initiate the drag operation with the proper source and type
    [self dragImage:dragImage  // Image to show during drag
                 at:dragPosition   // Drag start position
             offset:NSZeroSize
              event:event
         pasteboard:pasteboard
             source:self            // Set the DockIcon as the source
          slideBack:YES];            // If the drag is canceled, the icon returns to its original position
    
    
    _isDragging = NO;
    [self setNeedsDisplay:YES];
}

// Specify that this DockIcon supports the private drag operation
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationPrivate;
}

- (NSImage *)drawImage:(NSImage *)image withSize:(NSSize)size {
    // Create a new image with the provided size
    NSImage *newImage = [[NSImage alloc] initWithSize:size];

    // Lock focus on the new image to draw the original image into it
    [newImage lockFocus];
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver  // Use NSCompositeSourceOver for GNUstep
             fraction:1.0];
    [newImage unlockFocus];

    // Return the newly created image
    return newImage;
}

@end

