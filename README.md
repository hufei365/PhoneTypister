# PhoneTypist

> iPhone 作为 Windows 语音输入设备

## 项目简介

PhoneTypist 让 iPhone 手机作为 Windows 电脑的语音输入器：
- 在 iPhone 上通过语音输入
- iPhone 将语音转换为文字
- 文字发送到 Windows 电脑
- Windows 在光标位置自动输入文字

## 使用场景

- Windows 原生语音输入体验较差
- 配合 AI Agent 使用，语音比打字效率更高

## 系统架构

```
iPhone App (语音识别 + 发送)  ←WebSocket→  Windows Client (托盘 + 键盘模拟)
```

## 快速开始

### Windows 客户端

```bash
cd windows/PhoneTypist
dotnet build
dotnet run
```

启动后会显示托盘图标，双击显示 QR码供 iPhone 扫码配对。

### iPhone App

1. 在 Xcode 中打开 `ios/PhoneTypist` 项目
2. 构建并运行到 iPhone
3. 扫描 Windows 显示的 QR码配对
4. 按住麦克风按钮说话，点击发送

## 技术栈

| 平台 | 技术 |
|------|------|
| iPhone | Swift + SFSpeechRecognizer + Starscream |
| Windows | C# WPF + QRCoder + InputSimulator |

## 目录结构

```
phonetypist/
├── ios/                    # iPhone App
│   └── PhoneTypist/
│       ├── Features/
│       │   ├── SpeechRecognition/
│       │   ├── WebSocketConnection/
│       │   ├── QRScanner/
│       │   └── Pairing/
│       ├── Models/
│       └── UI/
│
├── windows/                # Windows Client
│   └── PhoneTypist/
│       ├── TrayIcon/
│       ├── WebSocketServer/
│       ├── KeyboardSimulator/
│       ├── QRGenerator/
│       └── Models/
│
├── docs/
│   └ plans/
│
└── README.md
```

## 功能

- [x] QR码配对机制
- [x] WebSocket 局域网通信
- [x] iPhone 语音识别（实时转录）
- [x] Windows 托盘应用（状态显示）
- [x] 键盘模拟输入（支持中文）

## 许可证

MIT License