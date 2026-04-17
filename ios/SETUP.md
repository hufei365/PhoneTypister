# PhoneTypist iOS - Swift Project Setup Guide

## 快速开始

项目已配置完成，使用 Xcode 打开 `ios/PhoneTypistApp/PhoneTypistApp.xcodeproj` 即可。

## 配置开发者信息

首次使用前，需要配置你的 Apple Developer Team ID 和 Bundle Identifier：

1. 复制配置模板：
   ```bash
   cd ios/PhoneTypistApp/PhoneTypistApp
   cp Config.example.xcconfig Config.xcconfig
   ```

2. 编辑 `Config.xcconfig`，填入你的信息：
   ```
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   PRODUCT_BUNDLE_IDENTIFIER = yourname.PhoneTypistApp
   ```

   - `DEVELOPMENT_TEAM`: 在 Xcode 菜单 Preferences → Accounts 中查看你的 Team ID
   - `PRODUCT_BUNDLE_IDENTIFIER`: 修改为你的唯一标识符

**注意**: `Config.xcconfig` 已在 `.gitignore` 中排除，不会被提交到版本库。

## 在 Xcode 中创建项目（历史参考）

以下步骤已在项目中完成，仅供参考：

1. 打开 Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "App" (iOS)
4. 填写项目信息：
   - Product Name: `PhoneTypist`
   - Team: 你的开发者账号
   - Organization Identifier: `com.yourname`
   - Bundle Identifier: `com.yourname.PhoneTypist`
   - Language: Swift
   - Interface: UIKit (Storyboard 或 SwiftUI 都可以，我们用 UIKit)

5. 选择保存位置为: `ios/PhoneTypist` 目录

## 添加依赖

### 使用 Swift Package Manager (推荐)

在 Xcode 中：
1. File → Add Packages...
2. 添加 Starscream:
   - URL: `https://github.com/daltoniam/Starscream.git`
   - Version: `4.0.6` 或更高

### 或使用 CocoaPods

在 `ios/` 目录创建 `Podfile`:

```ruby
platform :ios, '13.0'

target 'PhoneTypist' do
  use_frameworks!
  pod 'Starscream', '~> 4.0'
end
```

运行: `pod install`

## 导入源文件

创建项目后，将以下源文件导入到对应目录：

### Models (直接拖入 Models 组)
- ConnectionState.swift
- Message.swift  
- PairedDevice.swift

### Features (创建 Features 组)
- Features/SpeechRecognition/SpeechRecognitionManager.swift
- Features/WebSocketConnection/WebSocketClient.swift
- Features/QRScanner/QRScannerController.swift
- Features/Pairing/PairingManager.swift

### UI
- UI/MainViewController.swift

### App (根目录)
- AppDelegate.swift
- SceneDelegate.swift

### Resources
- Resources/Info.plist (替换 Xcode 生成的 Info.plist，或合并权限描述)

## 配置 Info.plist 权限

确保 Info.plist 包含：
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`  
- `NSCameraUsageDescription`

示例模板已包含，可直接使用或合并到项目 Info.plist。

## 配置 Storyboard/Scene

如果使用 Storyboard:
- 删除 Main.storyboard
- 在 SceneDelegate 中手动创建窗口和视图控制器

代码已配置为手动创建窗口，无需 Storyboard。

## 运行

1. 选择目标设备 (iPhone 或模拟器)
2. 点击 Run 按钮
3. 授权麦克风和语音识别权限
4. 测试扫描 QR 码配对功能

## 注意事项

- 需要真机测试语音识别和 QR 扫描
- 确保设备和 Windows PC 在同一局域网
- 首次运行需要授权麦克风、语音识别、相机权限