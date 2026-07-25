import SwiftUI
import UIKit

/// Jediný zdroj pravdy pro `isIdleTimerDisabled`.
/// Obrazovka zůstane zapnutá jen když je opravdu vidět detail zápasu.
@MainActor
final class IdleTimerController: ObservableObject {
    private var matchDetailVisible = false

    func setMatchDetailVisible(_ visible: Bool) {
        matchDetailVisible = visible
        apply()
    }

    /// Vynutí zhasínání podle nastavení iPhonu (Domů a ostatní root obrazovky).
    func allowSleep() {
        matchDetailVisible = false
        apply()
    }

    func apply() {
        UIApplication.shared.isIdleTimerDisabled = matchDetailVisible
    }
}

extension View {
    /// Domů / root: vždy povol zhasínání, jakmile je obrazovka vidět.
    func allowScreenSleepWhileVisible() -> some View {
        background(IdleTimerGateRepresentable(mode: .allowSleep))
    }

    /// Detail zápasu: dokud je view na obrazovce, iPhone nezhasne.
    func keepScreenOnWhileVisible() -> some View {
        background(IdleTimerGateRepresentable(mode: .keepAwake))
    }
}

private enum IdleTimerGateMode {
    case allowSleep
    case keepAwake
}

private struct IdleTimerGateRepresentable: UIViewControllerRepresentable {
    let mode: IdleTimerGateMode

    func makeUIViewController(context: Context) -> IdleTimerGateViewController {
        IdleTimerGateViewController(mode: mode)
    }

    func updateUIViewController(_ uiViewController: IdleTimerGateViewController, context: Context) {
        uiViewController.mode = mode
    }
}

private final class IdleTimerGateViewController: UIViewController {
    var mode: IdleTimerGateMode
    private var isArmed = false

    init(mode: IdleTimerGateMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyForCurrentVisibility(force: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyForCurrentVisibility(force: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disarm()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disarm()
    }

    private func applyForCurrentVisibility(force: Bool) {
        guard force || view.window != nil else { return }

        switch mode {
        case .allowSleep:
            IdleTimerAccess.allowSleep()
            isArmed = false
        case .keepAwake:
            guard view.window != nil else { return }
            IdleTimerAccess.setMatchDetailVisible(true)
            isArmed = true
        }
    }

    private func disarm() {
        guard mode == .keepAwake, isArmed else { return }
        isArmed = false
        IdleTimerAccess.setMatchDetailVisible(false)
    }
}

/// Globální přístup bez nutnosti propisat Environment všude do UIKit callbacků.
@MainActor
enum IdleTimerAccess {
    static weak var controller: IdleTimerController?

    static func setMatchDetailVisible(_ visible: Bool) {
        if let controller {
            controller.setMatchDetailVisible(visible)
        } else {
            UIApplication.shared.isIdleTimerDisabled = visible
        }
    }

    static func allowSleep() {
        if let controller {
            controller.allowSleep()
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
