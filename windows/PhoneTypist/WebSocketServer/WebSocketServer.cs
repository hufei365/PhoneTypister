using System;
using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using PhoneTypist.KeyboardSimulator;

namespace PhoneTypist.WebSocketServer
{
    public class PhoneTypistWebSocketServer : IDisposable
    {
        private readonly int _port;
        private readonly ConnectionStateManager _stateManager;
        private readonly global::PhoneTypist.KeyboardSimulator.IKeyboardSimulator? _keyboardSimulator;
        private readonly ILogger? _logger;

        private HttpListener? _httpListener;
        private CancellationTokenSource? _cts;
        private WebSocket? _currentClient;
        private bool _disposed;

        public ConnectionStateManager State => _stateManager;

        public event EventHandler<PhoneMessage>? MessageReceived;
        public event EventHandler<string>? ClientConnected;
        public event EventHandler<string>? ClientDisconnected;
        public event EventHandler<Exception>? ServerError;

        public PhoneTypistWebSocketServer(
            int port = 8765,
            global::PhoneTypist.KeyboardSimulator.IKeyboardSimulator? keyboardSimulator = null,
            ILogger? logger = null)
        {
            _port = port;
            _stateManager = new ConnectionStateManager();
            _keyboardSimulator = keyboardSimulator;
            _logger = logger;
        }

        public async Task StartAsync(CancellationToken cancellationToken = default)
        {
            ObjectDisposedException.ThrowIf(_disposed, this);

            if (_stateManager.State == ConnectionState.Listening ||
                _stateManager.State == ConnectionState.ClientConnected)
            {
                return;
            }

            _cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            _httpListener = new HttpListener();

            var prefix = $"http://+:{_port}/";
            _httpListener.Prefixes.Add(prefix);

            try
            {
                _httpListener.Start();
                _stateManager.TransitionTo(ConnectionState.Listening);
                _logger?.LogInfo($"WebSocket server listening on port {_port}");

                _ = AcceptLoopAsync(_cts.Token);
            }
            catch (HttpListenerException ex)
            {
                _stateManager.TransitionTo(ConnectionState.Error, ex.Message);
                _logger?.LogError($"Failed to start server: {ex.Message}");
                ServerError?.Invoke(this, ex);
                throw; // 重新抛出异常，让调用者知道启动失败
            }
        }

        public async Task StopAsync()
        {
            _cts?.Cancel();
            _currentClient?.Dispose();
            _currentClient = null;

            try
            {
                _httpListener?.Stop();
            }
            catch (ObjectDisposedException) { }
            catch (HttpListenerException) { }

            _stateManager.TransitionTo(ConnectionState.Stopped);
            _logger?.LogInfo("WebSocket server stopped");

            await Task.CompletedTask;
        }

        private async Task AcceptLoopAsync(CancellationToken ct)
        {
            _logger?.LogInfo("Accept loop started, waiting for connections...");
            while (!ct.IsCancellationRequested && _httpListener?.IsListening == true)
            {
                try
                {
                    _logger?.LogInfo("Waiting for HTTP request...");
                    var httpContext = await _httpListener.GetContextAsync();
                    
                    _logger?.LogInfo($"HTTP request received from: {httpContext.Request.RemoteEndPoint?.ToString() ?? "unknown"}");
                    _logger?.LogInfo($"Request URL: {httpContext.Request.Url?.ToString() ?? "unknown"}");
                    _logger?.LogInfo($"Is WebSocket request: {httpContext.Request.IsWebSocketRequest}");

                    if (!httpContext.Request.IsWebSocketRequest)
                    {
                        _logger?.LogError($"Rejected non-WebSocket request, closing with 400");
                        httpContext.Response.StatusCode = 400;
                        httpContext.Response.Close();
                        continue;
                    }

                    _logger?.LogInfo("Accepting WebSocket upgrade...");
                    var wsContext = await httpContext.AcceptWebSocketAsync(null);
                    var webSocket = wsContext.WebSocket;

                    if (_currentClient != null && _currentClient.State == WebSocketState.Open)
                    {
                        await _currentClient.CloseAsync(WebSocketCloseStatus.PolicyViolation,
                            "Another client connected", CancellationToken.None);
                        _currentClient.Dispose();
                    }

                    _currentClient = webSocket;
                    var clientInfo = httpContext.Request.RemoteEndPoint?.ToString() ?? "unknown";
                    _stateManager.TransitionTo(ConnectionState.ClientConnected);
                    _logger?.LogInfo($"Client connected: {clientInfo}");
                    ClientConnected?.Invoke(this, clientInfo);

                    _ = HandleClientAsync(webSocket, clientInfo, ct);
                }
                catch (ObjectDisposedException) { break; }
                catch (HttpListenerException) when (ct.IsCancellationRequested) { break; }
                catch (Exception ex)
                {
                    _logger?.LogError($"Accept error: {ex.Message}");
                    ServerError?.Invoke(this, ex);
                }
            }
        }

        private async Task HandleClientAsync(WebSocket webSocket, string clientInfo, CancellationToken ct)
        {
            var buffer = new byte[4096];

            try
            {
                while (webSocket.State == WebSocketState.Open && !ct.IsCancellationRequested)
                {
                    using var ms = new System.IO.MemoryStream();
                    WebSocketReceiveResult result;

                    do
                    {
                        result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), ct);
                        ms.Write(buffer, 0, result.Count);
                    } while (!result.EndOfMessage);

                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Client closed", CancellationToken.None);
                        break;
                    }

                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        var json = Encoding.UTF8.GetString(ms.ToArray());
                        _logger?.LogInfo($"Received: {json}");

                        var message = PhoneMessage.FromJson(json);
                        if (message == null)
                        {
                            _logger?.LogError($"Failed to parse message: {json}");
                            continue;
                        }

                        MessageReceived?.Invoke(this, message);

                        if (message.IsValidTextMessage())
                        {
                            _keyboardSimulator?.TypeText(message.Content);

                            var ack = ServerMessage.Acknowledge(message.Type);
                            await SendToClientAsync(ack.ToJson(), CancellationToken.None);
                        }
                    }
                }
            }
            catch (WebSocketException ex)
            {
                _logger?.LogError($"WebSocket error: {ex.Message}");
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested) { }
            finally
            {
                if (_currentClient == webSocket)
                {
                    _currentClient = null;
                    _stateManager.TransitionTo(ConnectionState.Listening);
                }

                _logger?.LogInfo($"Client disconnected: {clientInfo}");
                ClientDisconnected?.Invoke(this, clientInfo);
                webSocket.Dispose();
            }
        }

        private async Task SendToClientAsync(string message, CancellationToken ct)
        {
            if (_currentClient?.State == WebSocketState.Open)
            {
                var bytes = Encoding.UTF8.GetBytes(message);
                await _currentClient.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, ct);
            }
        }

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;

            _cts?.Cancel();
            _cts?.Dispose();
            _currentClient?.Dispose();
            _httpListener?.Close();
        }
    }

    public interface ILogger
    {
        void LogInfo(string message);
        void LogError(string message);
    }

    /// <summary>
    /// 简单的控制台日志实现，用于调试
    /// </summary>
    public class ConsoleLogger : ILogger
    {
        private readonly string _prefix;

        public ConsoleLogger(string prefix = "[PhoneTypist]")
        {
            _prefix = prefix;
        }

        public void LogInfo(string message)
        {
            Console.WriteLine($"{_prefix} INFO: {message}");
        }

        public void LogError(string message)
        {
            Console.WriteLine($"{_prefix} ERROR: {message}");
        }
    }
}
