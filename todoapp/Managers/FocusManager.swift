import SwiftUI

@Observable
final class FocusManager {
    enum State { case idle, active, paused }

    var state: State = .idle
    var elapsed: TimeInterval = 0
    var duration: TimeInterval = 25 * 60

    private var timer: Timer?

    var progress: Double {
        duration > 0 ? elapsed / duration : 0
    }

    var remaining: TimeInterval {
        max(0, duration - elapsed)
    }

    var remainingString: String {
        let t = Int(remaining)
        let m = t / 60
        let s = t % 60
        return "\(String(format: "%02d", m)):\(String(format: "%02d", s))"
    }

    var isActive: Bool { state == .active || state == .paused }

    func start() {
        state = .active
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 1
            if elapsed >= duration {
                finish()
            }
        }
    }

    func togglePause() {
        switch state {
        case .active:
            state = .paused
            timer?.invalidate()
        case .paused:
            state = .active
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self else { return }
                elapsed += 1
                if elapsed >= duration {
                    finish()
                }
            }
        default: break
        }
    }

    func finish() {
        timer?.invalidate()
        timer = nil
        state = .idle
        elapsed = 0
    }

    func setDuration(_ minutes: Double) {
        duration = minutes * 60
    }
}
