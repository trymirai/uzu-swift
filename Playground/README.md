<p align="center">
  <picture>
    <img alt="Mirai" src="https://artifacts.trymirai.com/social/github/uzu-swift-header.jpg" style="max-width: 100%;">
  </picture>
</p>

<a href="https://storage.googleapis.com/artifacts-bucket-cd05ceb/social/about_us.mp3"><img src="https://img.shields.io/badge/Listen-Podcast-red" alt="Listen to our podcast"></a>
<a href="https://docsend.com/v/76bpr/mirai2025"><img src="https://img.shields.io/badge/View-Deck-red" alt="View our deck"></a>
<a href="mailto:alexey@getmirai.co,dima@getmirai.co,aleksei@getmirai.co?subject=Interested%20in%20Mirai"><img src="https://img.shields.io/badge/Send-Email-green" alt="Contact us"></a>
<a href="https://docs.trymirai.com/components/inference-engine"><img src="https://img.shields.io/badge/Read-Docs-blue" alt="Read docs"></a>
[![Swift Version](https://img.shields.io/badge/Swift-5.9-blue)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

# Playground

Playground app for [uzu](https://github.com/trymirai/uzu), a **high-performance** inference engine for AI models on Apple Silicon.

## Usage

This sample app uses **XcodeGen** and **SwiftGen** to keep the Xcode project file and generated resources out of source control.

Install the required command-line tools:

```bash
brew install xcodegen swiftgen
```

Set up your project via [Platform](https://platform.trymirai.com), obtain an `API_KEY`, and paste it into `Sources/APIKey.swift`:

```swift
enum APIKey {
    static let mirai = "API_KEY"
}
```

From this directory (the one that contains `project.yml`) generate the Xcode project:

```bash
xcodegen
```
