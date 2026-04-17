using System.Windows;
using Hardcodet.Wpf.TaskbarNotification;

namespace PhoneTypist;

public partial class App : Application
{
    private TaskbarIcon? _notifyIcon;
    private NotifyIconViewModel? _viewModel;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // Create the ViewModel
        _viewModel = new NotifyIconViewModel();

        // Find the TaskbarIcon resource and assign the ViewModel
        _notifyIcon = (TaskbarIcon)FindResource("NotifyIcon");
        if (_notifyIcon != null)
        {
            _notifyIcon.DataContext = _viewModel;
        }

        // Ensure the taskbar icon is initialized
        // Note: ForceCreation() was removed in Hardcodet.NotifyIcon.Wpf 1.1.0
        // The TaskbarIcon created from XAML resources initializes automatically
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _notifyIcon?.Dispose();
        base.OnExit(e);
    }
}
