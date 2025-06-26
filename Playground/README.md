# Playground – Project Generation Guide

## Features

- Powered by **Uzu** – Mirai's on-device, Metal-accelerated LLM engine.
- Browse the remote model registry and manage downloads (pause / resume / delete).
- General **chat** interface with live streaming tokens.
- **Classification** demo (sentiment analysis by default) showing zero-shot labelling.
- **Summarisation** demo that condenses long text input.

## Usage

This sample app uses **XcodeGen** and **SwiftGen** to keep the Xcode project file and generated resources out of source control.

1. Install the required command-line tools:

```bash
brew install xcodegen swiftgen
```

2. Grab your Mirai API key from <https://platform.trymirai.com/> and paste it into `Sources/APIKey.swift`:

```swift
enum APIKey {
    static let mirai = "<#YOUR_MIRAI_API_KEY#>"
}
```

3. From this directory (the one that contains `project.yml`) generate the Xcode project:

```bash
xcodegen
```
