using QRCoder;
using System.Drawing;
using System.IO;

namespace PhoneTypist.QRGenerator;

public interface IQRGenerator
{
    Bitmap GenerateQRCode(string content, int pixelSize = 20);
    byte[] GenerateQRCodeBytes(string content, int pixelSize = 20);
}

public class QRGenerator : IQRGenerator
{
    public Bitmap GenerateQRCode(string content, int pixelSize = 20)
    {
        using var qrGenerator = new QRCodeGenerator();
        var qrCodeData = qrGenerator.CreateQrCode(content, QRCodeGenerator.ECCLevel.Q);
        using var qrCode = new QRCode(qrCodeData);
        return qrCode.GetGraphic(pixelSize);
    }

    public byte[] GenerateQRCodeBytes(string content, int pixelSize = 20)
    {
        using var bitmap = GenerateQRCode(content, pixelSize);
        using var stream = new MemoryStream();
        bitmap.Save(stream, System.Drawing.Imaging.ImageFormat.Png);
        return stream.ToArray();
    }
}