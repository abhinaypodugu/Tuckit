import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#endif

enum Haptics {
    static func tap(_ enabled: Bool) {
        #if os(iOS)
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
