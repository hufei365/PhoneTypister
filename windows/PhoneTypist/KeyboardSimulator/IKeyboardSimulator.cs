namespace PhoneTypist.KeyboardSimulator;

/// <summary>
/// Abstraction for keyboard text input simulation.
/// Used for dependency injection and unit testing.
/// </summary>
public interface IKeyboardSimulator
{
    /// <summary>
    /// Type the given text at the current cursor position.
    /// Supports Unicode characters including Chinese (CJK).
    /// </summary>
    /// <param name="text">The text to type.</param>
    /// <returns>True if typing succeeded, false otherwise.</returns>
    bool TypeText(string text);
}
