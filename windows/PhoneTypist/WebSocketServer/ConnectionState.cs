using System;

namespace PhoneTypist.WebSocketServer
{
    public enum ConnectionState
    {
        Stopped,
        Listening,
        ClientConnected,
        Error
    }

    public class ConnectionStateManager
    {
        private readonly object _lock = new();
        private ConnectionState _state = ConnectionState.Stopped;
        private string? _errorMessage;

        public ConnectionState State
        {
            get { lock (_lock) { return _state; } }
        }

        public string? ErrorMessage
        {
            get { lock (_lock) { return _errorMessage; } }
        }

        public event EventHandler<ConnectionStateChangedEventArgs>? StateChanged;

        public void TransitionTo(ConnectionState newState, string? errorMessage = null)
        {
            ConnectionState oldState;
            lock (_lock)
            {
                oldState = _state;
                if (oldState == newState && _errorMessage == errorMessage) return;
                _state = newState;
                _errorMessage = errorMessage;
            }

            StateChanged?.Invoke(this, new ConnectionStateChangedEventArgs(oldState, newState, errorMessage));
        }
    }

    public class ConnectionStateChangedEventArgs : EventArgs
    {
        public ConnectionState PreviousState { get; }
        public ConnectionState CurrentState { get; }
        public string? ErrorMessage { get; }

        public ConnectionStateChangedEventArgs(ConnectionState previous, ConnectionState current, string? error = null)
        {
            PreviousState = previous;
            CurrentState = current;
            ErrorMessage = error;
        }
    }
}
