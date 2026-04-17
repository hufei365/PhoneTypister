using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;

namespace PhoneTypist;

public enum ConnectionStatus
{
    Waiting,
    Connected,
    Error
}

public class NotifyIconViewModel : INotifyPropertyChanged
{
    private ConnectionStatus _status = ConnectionStatus.Waiting;
    private string _statusText = "Status: Waiting...";
    private string _connectedDevice = string.Empty;
    private string _lastReceived = string.Empty;
    private MainWindow? _qrWindow; // 单例窗口引用

    public event PropertyChangedEventHandler? PropertyChanged;

    public ICommand ShowQrWindowCommand { get; }
    public ICommand ExitCommand { get; }

    public NotifyIconViewModel()
    {
        ShowQrWindowCommand = new RelayCommand(ShowQrWindow);
        ExitCommand = new RelayCommand(ExitApplication);
    }

    public ConnectionStatus Status
    {
        get => _status;
        set
        {
            if (_status != value)
            {
                _status = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(TrayIconSource));
                OnPropertyChanged(nameof(TrayToolTipText));
                UpdateStatusText();
            }
        }
    }

    public string StatusText
    {
        get => _statusText;
        set
        {
            if (_statusText != value)
            {
                _statusText = value;
                OnPropertyChanged();
            }
        }
    }

    public string ConnectedDevice
    {
        get => _connectedDevice;
        set
        {
            if (_connectedDevice != value)
            {
                _connectedDevice = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(TrayToolTipText));
            }
        }
    }

    public string LastReceived
    {
        get => _lastReceived;
        set
        {
            if (_lastReceived != value)
            {
                _lastReceived = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(LastReceivedDisplay));
            }
        }
    }

    public string LastReceivedDisplay =>
        string.IsNullOrEmpty(_lastReceived) ? "No messages yet" :
        _lastReceived.Length > 30 ? $"Latest: {_lastReceived[..30]}..." : $"Latest: {_lastReceived}";

    public string TrayIconSource => Status switch
    {
        ConnectionStatus.Waiting => "pack://application:,,,/resources/icon_waiting.ico",
        ConnectionStatus.Connected => "pack://application:,,,/resources/icon_connected.ico",
        ConnectionStatus.Error => "pack://application:,,,/resources/icon_error.ico",
        _ => "pack://application:,,,/resources/icon_waiting.ico"
    };

    public string TrayToolTipText => Status switch
    {
        ConnectionStatus.Waiting => "PhoneTypist - Waiting for connection",
        ConnectionStatus.Connected => $"PhoneTypist - Connected to {ConnectedDevice}",
        ConnectionStatus.Error => "PhoneTypist - Connection error",
        _ => "PhoneTypist"
    };

    private void ShowQrWindow()
    {
        // 如果窗口已存在且未关闭，激活已有窗口
        if (_qrWindow != null && !_qrWindow.IsLoaded)
        {
            _qrWindow = null;
        }

        if (_qrWindow != null)
        {
            _qrWindow.Activate();
            return;
        }

        // 创建新窗口并保存引用
        _qrWindow = new MainWindow { DataContext = this };
        _qrWindow.Closed += (s, e) => _qrWindow = null; // 窗口关闭时清空引用
        _qrWindow.Show();
        _qrWindow.Activate();
    }

    private void ExitApplication()
    {
        Application.Current.Shutdown();
    }

    private void UpdateStatusText()
    {
        StatusText = Status switch
        {
            ConnectionStatus.Waiting => "Status: Waiting...",
            ConnectionStatus.Connected => $"Status: Connected ({ConnectedDevice})",
            ConnectionStatus.Error => "Status: Error",
            _ => "Status: Unknown"
        };
    }

    protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
