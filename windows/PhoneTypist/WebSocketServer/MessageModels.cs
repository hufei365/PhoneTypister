using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PhoneTypist.WebSocketServer
{
    /// <summary>
    /// Messages received from the iPhone client.
    /// Format: { "type": "text", "content": "...", "timestamp": 1710000000000 }
    /// </summary>
    public class PhoneMessage
    {
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true
        };

        [JsonPropertyName("type")]
        public string Type { get; set; } = string.Empty;

        [JsonPropertyName("content")]
        public string Content { get; set; } = string.Empty;

        [JsonPropertyName("timestamp")]
        public long Timestamp { get; set; }

        /// <summary>
        /// Converts the Unix millisecond timestamp to a DateTime.
        /// </summary>
        [JsonIgnore]
        public DateTime TimestampUtc => DateTimeOffset.FromUnixTimeMilliseconds(Timestamp).UtcDateTime;

        /// <summary>
        /// Parses a JSON string into a PhoneMessage.
        /// Returns null if parsing fails.
        /// </summary>
        public static PhoneMessage? FromJson(string json)
        {
            try
            {
                return JsonSerializer.Deserialize<PhoneMessage>(json, JsonOptions);
            }
            catch (JsonException)
            {
                return null;
            }
        }

        /// <summary>
        /// Validates that the message has the required fields for a text message.
        /// </summary>
        public bool IsValidTextMessage()
        {
            return Type == "text" && !string.IsNullOrEmpty(Content);
        }
    }

    /// <summary>
    /// Messages sent from server to iPhone client (acknowledgements, status).
    /// </summary>
    public class ServerMessage
    {
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        [JsonPropertyName("type")]
        public string Type { get; set; } = string.Empty;

        [JsonPropertyName("content")]
        public string Content { get; set; } = string.Empty;

        [JsonPropertyName("timestamp")]
        public long Timestamp { get; set; } = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        public string ToJson()
        {
            return JsonSerializer.Serialize(this, JsonOptions);
        }

        public static ServerMessage Acknowledge(string originalType)
        {
            return new ServerMessage
            {
                Type = "ack",
                Content = $"Received: {originalType}"
            };
        }

        public static ServerMessage Error(string errorMessage)
        {
            return new ServerMessage
            {
                Type = "error",
                Content = errorMessage
            };
        }
    }
}
