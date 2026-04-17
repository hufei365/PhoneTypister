# PhoneTypist Windows - Setup Guide

## Prerequisites

- Windows 10/11
- .NET 8 SDK installed
- Visual Studio 2022 or later (or VS Code with C# extension)

## Build and Run

```powershell
cd windows/PhoneTypist
dotnet build
dotnet run
```

## Icon Setup

The application uses tray icons to show connection status. You need to place icon files in `Resources/`:

- `app.ico` - Main application icon
- `icon_waiting.ico` - Blue icon (waiting for connection)
- `icon_connected.ico` - Green icon (connected)
- `icon_error.ico` - Red icon (error)

You can create these icons using any icon editor, or download free icons from sites like:
- https://icons8.com
- https://flaticon.com

### Quick Icon Creation

If you don't have icons, you can modify `NotifyIconViewModel.cs` to use system icons:

```csharp
// Instead of pack:// URIs, use:
public string TrayIconSource => Status switch
{
    ConnectionStatus.Waiting => "Resources/icon_waiting.ico",
    ConnectionStatus.Connected => "Resources/icon_connected.ico",
    ConnectionStatus.Error => "Resources/icon_error.ico",
    _ => "Resources/icon_waiting.ico"
};
```

Or create simple colored square icons programmatically in `App.xaml.cs`.

## Configuration

Default settings:
- Port: 8765
- Protocol: WebSocket

Modify `_port` in `MainWindow.xaml.cs` to change the port.

## Firewall

If connection fails, check Windows Firewall:

```powershell
# Allow the port
netsh advfirewall firewall add rule name="PhoneTypist" dir=in action=allow protocol=tcp localport=8765
```

## Troubleshooting

### "Failed to start server"
- Check if port 8765 is already in use: `netstat -an | findstr 8765`
- Try a different port

### iPhone cannot connect
- Ensure both devices are on the same network
- Check firewall settings
- Verify the QR code contains correct IP

### Keyboard input doesn't work
- Some applications block simulated input (games, secure apps)
- Try testing with Notepad first

## Dependencies

NuGet packages (auto-installed):
- Hardcodet.NotifyIcon.Wpf (tray icon)
- QRCoder (QR code generation)
- InputSimulatorPlus (keyboard simulation)