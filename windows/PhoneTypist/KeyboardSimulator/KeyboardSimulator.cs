using System;
using WindowsInput;

namespace PhoneTypist.KeyboardSimulator;

/// <summary>
/// Simulates keyboard input using the InputSimulator NuGet package.
/// Types text at the current cursor position, including Unicode / Chinese characters.
/// </summary>
/// <remarks>
/// Requires NuGet package: InputSimulatorPlus
///   https://github.com/michaelnoonan/inputsimulator
///
/// Usage:
///   var sim = new KeyboardSimulator();
///   sim.TypeText("你好世界");   // Chinese
///   sim.TypeText("Hello 世界"); // Mixed
///
/// For DI, register via IKeyboardSimulator interface:
///   services.AddSingleton&lt;IKeyboardSimulator, KeyboardSimulator&gt;();
/// </remarks>
public class KeyboardSimulator : IKeyboardSimulator
{
    private readonly int _charDelayMs;

    /// <summary>
    /// Creates a new KeyboardSimulator.
    /// </summary>
    /// <param name="charDelayMs">
    /// Delay in milliseconds between each character.
    /// Set to 0 (default) for no delay — fastest typing.
    /// A value of 10-50ms can help with applications that drop rapid input.
    /// </param>
    public KeyboardSimulator(int charDelayMs = 0)
    {
        _charDelayMs = Math.Max(0, charDelayMs);
    }

    /// <inheritdoc />
    public bool TypeText(string text)
    {
        if (string.IsNullOrEmpty(text))
            return true;

        try
        {
            var simulator = new InputSimulator();

            if (_charDelayMs > 0)
            {
                TypeWithDelay(simulator, text);
            }
            else
            {
                simulator.Keyboard.TextEntry(text);
            }

            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    private void TypeWithDelay(InputSimulator simulator, string text)
    {
        foreach (char c in text)
        {
            simulator.Keyboard.TextEntry(c.ToString());
            if (_charDelayMs > 0)
            {
                System.Threading.Thread.Sleep(_charDelayMs);
            }
        }
    }
}
