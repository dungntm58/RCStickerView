# RCStickerView

[![CI Status](https://img.shields.io/travis/dungntm58/RCStickerView.svg?style=flat)](https://travis-ci.org/dungntm58/RCStickerView)
[![Version](https://img.shields.io/cocoapods/v/RCStickerView.svg?style=flat)](https://cocoapods.org/pods/RCStickerView)
[![License](https://img.shields.io/cocoapods/l/RCStickerView.svg?style=flat)](https://cocoapods.org/pods/RCStickerView)
[![Platform](https://img.shields.io/cocoapods/p/RCStickerView.svg?style=flat)](https://cocoapods.org/pods/RCStickerView)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Xcode 10.
- Swift 4.0.
- iOS 9.0 or higher.

## Installation

RCStickerView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RCStickerView'
```

Then, run the following command:

```bash
$ pod install
```

## Usage

See the `Example` project for more details.
```swift
override func viewDidLoad() {
  super.viewDidLoad()
  
  let testView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
  testView.backgroundColor = .red
  
  let stickerView = RCStickerView(contentView: testView)
  stickerView.center = self.view.center
  stickerView.delegate = self
  stickerView.outlineBorderColor = .blue
  stickerView.set(image: UIImage(named: "Close"), for: .close)
  stickerView.set(image: UIImage(named: "Rotate"), for: .rotate)
  stickerView.set(image: UIImage(named: "Flip"), for: .flipX)
  stickerView.isEnableFlipY = false
  stickerView.handlerSize = 40
  self.view.addSubview(stickerView)
}
```


## Inspiration

RCStickerView is heavily inspired by CHTStickerView.

## Author

RobertNguyen, minhdung.uet.work@gmail.com

## License

RCStickerView is available under the MIT license. See the LICENSE file for more info.
