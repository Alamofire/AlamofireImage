# Alamofire 3.0 Migration Guide

AlamofireImage 2.0 is the latest major release of AlamofireImage, an image component library for Alamofire supporting iOS, Mac OS X and watchOS written in Swift. As a major release, following Semantic Versioning conventions, 2.0 introduces several API-breaking changes that one should be aware of.

This guide is provided in order to ease the transition of existing applications using Alamofire 2.x to the latest APIs, as well as explain the design and structure of new and changed functionality.

## Requirements

AlamofireImage 2.0 officially supports iOS 8+, Mac OS X 10.9+, watchOS 2.0, Xcode 7 and Swift 2.0.

## Reasons for Bumping to 2.0

The [Alamofire Software Foundation](https://github.com/Alamofire/Foundation) (ASF) tries to do everything possible to avoid MAJOR version bumps. We realize the challenges involved with migrating large projects from one MAJOR version to another. The reason for bumping to 2.0 is due to the Alamofire 3.0 changes. We want to keep both libraries in sync, which requires changes to the foundational classes of AlamofireImage. The changes made to Alamofire give us more flexibility moving forward to help avoid the need for MAJOR version bumps to maintain backwards compatibility.

## Benefits of Upgrading

The benefits of upgrading can be summarized as follows:

TODO

---

## Breaking API Changes

AlamofireImage 2.0 contains some breaking API changes to the foundational classes supporting the response serialization system. It is important to understand how these changes affect the common usage patterns.

### Request Extension

TODO

### Image Downloader 

TODO

### UIImageView Extension

TODO
