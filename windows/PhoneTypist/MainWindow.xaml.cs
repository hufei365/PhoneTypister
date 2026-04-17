using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Windows;
using System.Windows.Media.Imaging;
using QRCoder;
using PhoneTypist.WebSocketServer;
using PhoneTypist.KeyboardSimulator;
using KeyboardSimulatorImpl = PhoneTypist.KeyboardSimulator.KeyboardSimulator;

namespace PhoneTypist;

public partial class MainWindow : Window
{
    private readonly PhoneTypistWebSocketServer _server;
    private readonly IKeyboardSimulator _keyboardSimulator;
    private readonly NotifyIconViewModel _viewModel;
    private readonly ConsoleLogger _logger;
    private string _ipAddress = "";
    private int _port = 8765;

    public MainWindow()
    {
        InitializeComponent();

        _logger = new ConsoleLogger();
        _keyboardSimulator = new KeyboardSimulatorImpl();
        var notifyIcon = Application.Current.FindResource("NotifyIcon") as Hardcodet.Wpf.TaskbarNotification.TaskbarIcon;
        _viewModel = notifyIcon?.DataContext as NotifyIconViewModel ?? new NotifyIconViewModel();
        _server = new PhoneTypistWebSocketServer(_port, _keyboardSimulator, _logger);

        _server.ClientConnected += OnClientConnected;
        _server.ClientDisconnected += OnClientDisconnected;
        _server.MessageReceived += OnMessageReceived;
        _server.ServerError += OnServerError;

        Loaded += OnLoaded;
        Closed += OnClosed;

        _logger.LogInfo("MainWindow initialized");
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        _ipAddress = GetLocalIpAddress();
        IpAddressText.Text = $"IP: {_ipAddress}";
        PortText.Text = $"Port: {_port}";

        _logger.LogInfo($"Local IP Address: {_ipAddress}");
        _logger.LogInfo($"WebSocket Port: {_port}");

        GenerateAndDisplayQRCode();

        try
        {
            _logger.LogInfo($"Starting WebSocket server on port {_port}...");
            await _server.StartAsync();
            _logger.LogInfo("WebSocket server started successfully");
            _logger.LogInfo($"Waiting for iPhone to scan QR code and connect...");
            _logger.LogInfo($"iPhone should connect to: ws://{_ipAddress}:{_port}/");
        }
        catch (Exception ex)
        {
            _logger.LogError($"Failed to start server: {ex.Message}");
            _viewModel.Status = ConnectionStatus.Error;
            MessageBox.Show($"Failed to start server: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
        }
    }

    private async void OnClosed(object? sender, EventArgs e)
    {
        await _server.StopAsync();
    }

    private static string GetLocalIpAddress()
    {
        // 优先检测热点接口（通常是 192.168.x.1 或类似地址）
        var hotspotIp = System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces()
            .Where(ni => ni.OperationalStatus == System.Net.NetworkInformation.OperationalStatus.Up)
            .SelectMany(ni => ni.GetIPProperties().UnicastAddresses)
            .Where(ip => ip.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
            .Where(ip => ip.Address.ToString().StartsWith("192.168.") || 
                         ip.Address.ToString().StartsWith("10.") ||
                         ip.Address.ToString().StartsWith("172.16.") ||
                         ip.Address.ToString().StartsWith("172.17.") ||
                         ip.Address.ToString().StartsWith("172.18.") ||
                         ip.Address.ToString().StartsWith("172.19.") ||
                         ip.Address.ToString().StartsWith("172.20.") ||
                         ip.Address.ToString().StartsWith("172.21.") ||
                         ip.Address.ToString().StartsWith("172.22.") ||
                         ip.Address.ToString().StartsWith("172.23.") ||
                         ip.Address.ToString().StartsWith("172.24.") ||
                         ip.Address.ToString().StartsWith("172.25.") ||
                         ip.Address.ToString().StartsWith("172.26.") ||
                         ip.Address.ToString().StartsWith("172.27.") ||
                         ip.Address.ToString().StartsWith("172.28.") ||
                         ip.Address.ToString().StartsWith("172.29.") ||
                         ip.Address.ToString().StartsWith("172.30.") ||
                         ip.Address.ToString().StartsWith("172.31."))
            .OrderByDescending(ip => ip.Address.ToString().StartsWith("192.168.")) // 热点优先
            .Select(ip => ip.Address.ToString())
            .FirstOrDefault();

        if (hotspotIp != null)
        {
            return hotspotIp;
        }

        // 回退：通过连接外部地址获取
        using var socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, 0);
        socket.Connect("8.8.8.8", 65530);
        var endPoint = socket.LocalEndPoint as IPEndPoint;
        return endPoint?.Address.ToString() ?? "127.0.0.1";
    }

    private void GenerateAndDisplayQRCode()
    {
        var payload = $"phonetypist://{_ipAddress}:{_port}";

        using var qrGenerator = new QRCodeGenerator();
        var qrCodeData = qrGenerator.CreateQrCode(payload, QRCodeGenerator.ECCLevel.M);
        using var qrCode = new PngByteQRCode(qrCodeData);
        var qrCodeBytes = qrCode.GetGraphic(7);

        using var stream = new MemoryStream(qrCodeBytes);
        var image = new BitmapImage();
        image.BeginInit();
        image.CacheOption = BitmapCacheOption.OnLoad;
        image.StreamSource = stream;
        image.EndInit();
        image.Freeze();

        QrCodeImage.Source = image;
    }

    private void OnClientConnected(object? sender, string clientInfo)
    {
        _logger.LogInfo($"Client connected: {clientInfo}");
        Dispatcher.Invoke(() =>
        {
            _viewModel.Status = ConnectionStatus.Connected;
            _viewModel.ConnectedDevice = "iPhone";
        });
    }

    private void OnClientDisconnected(object? sender, string clientInfo)
    {
        _logger.LogInfo($"Client disconnected: {clientInfo}");
        Dispatcher.Invoke(() =>
        {
            _viewModel.Status = ConnectionStatus.Waiting;
            _viewModel.ConnectedDevice = "";
        });
    }

    private void OnMessageReceived(object? sender, PhoneMessage message)
    {
        _logger.LogInfo($"Message received: type={message.Type}, content={message.Content}");
        Dispatcher.Invoke(() =>
        {
            _viewModel.LastReceived = message.Content;
        });
    }

    private void OnServerError(object? sender, Exception ex)
    {
        _logger.LogError($"Server error: {ex.Message}");
        Dispatcher.Invoke(() =>
        {
            _viewModel.Status = ConnectionStatus.Error;
        });
    }
}