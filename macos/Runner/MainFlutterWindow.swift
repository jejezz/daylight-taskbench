import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // 창은 Flutter 가 첫 프레임을 그리고 크기·위치를 정한 뒤 Dart 의 windowManager.show() 로 보인다.
  // 이 재정의가 없으면 .xib 의 800×600 빈 창이 먼저 떴다가 크기·위치가 바뀌며 깜빡인다 (window_manager 안내).
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
