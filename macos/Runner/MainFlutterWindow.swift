import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // 창은 투명한 채로 시작한다: .xib 의 800×600 빈 창이 보였다가 크기·위치가 바뀌며 깜빡이는 것을 막는다.
    // Dart(lib/main.dart)가 첫 프레임을 그리고 크기·위치를 정한 뒤 windowManager.setOpacity(1) 로 보인다.
    // 창을 숨기는(hiddenWindowAtLaunch·visibleAtLaunch=NO) 방법은 쓰지 않는다 — 보이지 않는 창은 Flutter 가 프레임을
    // 만들지 않아서 "첫 프레임 뒤에 보이기"가 영영 오지 않았다 (앱이 켜졌는데 창이 안 뜸).
    self.alphaValue = 0

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
