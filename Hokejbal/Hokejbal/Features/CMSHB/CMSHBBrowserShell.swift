import SwiftUI
import WebKit
import SafariServices

/// Oddělený CMSHB režim — živý web ve WKWebView. Stávající Hokejbal UI netýká.
struct CMSHBBrowserShell: View {
    @EnvironmentObject private var brandStore: AppBrandStore

    @StateObject private var webModel = CMSHBWebModel()
    @State private var showSiteSwitch = false
    @State private var safariItem: SafariURLItem?

    var body: some View {
        VStack(spacing: 0) {
            chrome
            progressBar
            CMSHBWebView(
                model: webModel,
                onOpenExternal: { safariItem = SafariURLItem(url: $0) },
                onSwitchToHokejbal: { brandStore.select(.hokejbal) }
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .background(HBTheme.canvas.ignoresSafeArea())
        .sheet(isPresented: $showSiteSwitch) {
            SiteSwitchSheet()
        }
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .onAppear {
            if webModel.url == nil {
                webModel.load(AppBrand.cmshb.homeURL)
            }
        }
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    showSiteSwitch = true
                } label: {
                    HStack(spacing: 8) {
                        BrandLogoImage(size: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CMSHb.CZ")
                                .font(.hbMontserrat(size: 14, weight: .bold))
                                .foregroundStyle(HBTheme.textPrimary)
                            Text("Přepnout web")
                                .font(.hbMontserrat(size: 11, weight: .medium))
                                .foregroundStyle(HBTheme.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Přepnout web")

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    chromeButton("chevron.backward", enabled: webModel.canGoBack) {
                        webModel.goBack()
                    }
                    chromeButton("chevron.forward", enabled: webModel.canGoForward) {
                        webModel.goForward()
                    }
                    chromeButton("arrow.clockwise", enabled: true) {
                        webModel.reload()
                    }
                }
            }
            .padding(.horizontal, HBTheme.screenPadding)
            .padding(.vertical, 10)

            Rectangle()
                .fill(HBTheme.separator)
                .frame(height: 0.5)
        }
        .background(HBTheme.surface)
    }

    private var progressBar: some View {
        Group {
            if webModel.isLoading {
                ProgressView(value: max(webModel.estimatedProgress, 0.05), total: 1)
                    .tint(HBTheme.brand)
                    .padding(.horizontal, 0)
            }
        }
        .frame(height: webModel.isLoading ? 2 : 0)
        .animation(.easeOut(duration: 0.2), value: webModel.isLoading)
    }

    private func chromeButton(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? HBTheme.textPrimary : HBTheme.textTertiary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Model

@MainActor
final class CMSHBWebModel: ObservableObject {
    @Published var url: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var estimatedProgress: Double = 0

    weak var webView: WKWebView?

    func load(_ url: URL) {
        self.url = url
        webView?.load(URLRequest(url: url))
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }

    func syncNavigationState(from webView: WKWebView) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        estimatedProgress = webView.estimatedProgress
        url = webView.url
    }
}

// MARK: - WKWebView bridge

struct CMSHBWebView: UIViewRepresentable {
    @ObservedObject var model: CMSHBWebModel
    var onOpenExternal: (URL) -> Void
    var onSwitchToHokejbal: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, onOpenExternal: onOpenExternal, onSwitchToHokejbal: onSwitchToHokejbal)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        model.webView = webView

        context.coordinator.observe(webView)

        if let url = model.url {
            webView.load(URLRequest(url: url))
        } else {
            webView.load(URLRequest(url: AppBrand.cmshb.homeURL))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        model.webView = uiView
        context.coordinator.onOpenExternal = onOpenExternal
        context.coordinator.onSwitchToHokejbal = onSwitchToHokejbal
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let model: CMSHBWebModel
        var onOpenExternal: (URL) -> Void
        var onSwitchToHokejbal: () -> Void
        private var observations: [NSKeyValueObservation] = []

        init(
            model: CMSHBWebModel,
            onOpenExternal: @escaping (URL) -> Void,
            onSwitchToHokejbal: @escaping () -> Void
        ) {
            self.model = model
            self.onOpenExternal = onOpenExternal
            self.onSwitchToHokejbal = onSwitchToHokejbal
        }

        func observe(_ webView: WKWebView) {
            teardown()
            observations = [
                webView.observe(\.canGoBack, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.model.syncNavigationState(from: wv) }
                },
                webView.observe(\.canGoForward, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.model.syncNavigationState(from: wv) }
                },
                webView.observe(\.isLoading, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.model.syncNavigationState(from: wv) }
                },
                webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.model.syncNavigationState(from: wv) }
                },
                webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                    Task { @MainActor in self?.model.syncNavigationState(from: wv) }
                },
            ]
        }

        func teardown() {
            observations.forEach { $0.invalidate() }
            observations.removeAll()
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if Self.isHokejbalHost(url) {
                decisionHandler(.cancel)
                Task { @MainActor in onSwitchToHokejbal() }
                return
            }

            if Self.isCMSHBHost(url) || url.scheme == "about" || url.scheme == "blob" {
                // Regionální weby někdy odkazují http:// — přesměruj na https.
                if url.scheme?.lowercased() == "http",
                   var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    comps.scheme = "https"
                    if let httpsURL = comps.url, httpsURL != url {
                        decisionHandler(.cancel)
                        webView.load(URLRequest(url: httpsURL))
                        return
                    }
                }
                decisionHandler(.allow)
                return
            }

            if let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                decisionHandler(.cancel)
                Task { @MainActor in onOpenExternal(url) }
                return
            }

            // mailto / tel / ostatní
            if UIApplication.shared.canOpenURL(url) {
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                if Self.isCMSHBHost(url) {
                    webView.load(URLRequest(url: url))
                } else if Self.isHokejbalHost(url) {
                    Task { @MainActor in onSwitchToHokejbal() }
                } else if url.scheme == "http" || url.scheme == "https" {
                    Task { @MainActor in onOpenExternal(url) }
                }
            }
            return nil
        }

        static func isCMSHBHost(_ url: URL) -> Bool {
            guard let host = url.host?.lowercased() else { return false }
            return host == "cmshb.cz" || host.hasSuffix(".cmshb.cz")
        }

        static func isHokejbalHost(_ url: URL) -> Bool {
            guard let host = url.host?.lowercased() else { return false }
            return host == "hokejbal.cz" || host.hasSuffix(".hokejbal.cz")
        }
    }
}

// MARK: - Safari sheet

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct SafariURLItem: Identifiable {
    let id = UUID()
    let url: URL
}
