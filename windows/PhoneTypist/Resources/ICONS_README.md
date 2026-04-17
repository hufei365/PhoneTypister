# Placeholder Icons

This directory should contain icon files for the tray application:

## Required Files

1. `app.ico` - Main application icon (shown in taskbar)
2. `icon_waiting.ico` - Blue icon for "waiting for connection" state
3. `icon_connected.ico` - Green icon for "connected" state  
4. `icon_error.ico` - Red icon for "error" state

## Creating Icons

### Option 1: Use Online Tools
- https://icoconvert.com/ (convert PNG to ICO)
- https://icons8.com (free icons)
- https://flaticon.com (free icons)

### Option 2: Use Visual Studio
1. Open Visual Studio
2. Add new resource file
3. Choose "Icon File"
4. Design 16x16 and 32x32 versions

### Option 3: Use System.Drawing (Programmatic)

Create a simple colored square icon:

```csharp
using System.Drawing;
using System.IO;

void CreateIcon(string filename, Color color)
{
    using var bitmap = new Bitmap(32, 32);
    using var graphics = Graphics.FromImage(bitmap);
    graphics.Clear(color);
    
    // Save as ICO (requires additional library or conversion)
    bitmap.Save(filename.Replace(".ico", ".png"));
    // Then convert PNG to ICO using online tool
}

CreateIcon("icon_waiting.png", Color.Blue);
CreateIcon("icon_connected.png", Color.Green);
CreateIcon("icon_error.png", Color.Red);
```

## Quick Fix

If you don't have icons ready, you can:

1. Copy any .ico file and rename it to `app.ico`
2. The tray will show a default icon if files are missing
3. Use the app without tray icon status colors initially

## Icon Sizes

Recommended sizes:
- 16x16 (taskbar)
- 32x32 (notification area)
- 48x48 (large)
- 256x256 (modern)