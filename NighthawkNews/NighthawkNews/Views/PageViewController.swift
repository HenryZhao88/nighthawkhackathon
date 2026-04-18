import SwiftUI
import UIKit

/// SwiftUI wrapper around `UIPageViewController` that delivers native
/// horizontal, momentum-preserving paging between the app's root tabs.
///
/// A single set of `UIHostingController`s is created once and kept alive for
/// the lifetime of the container so each page's SwiftUI state (scroll offsets,
/// the loaded feed, detail navigation, etc.) survives swipes and programmatic
/// tab changes without being torn down.
struct PageViewController<Page: View>: UIViewControllerRepresentable {
    let pages: [Page]
    @Binding var currentIndex: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: 0]
        )
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .clear

        // Let taps on cards / buttons fire immediately even while a horizontal
        // pan is beginning — keeps the interaction feeling native.
        for subview in pvc.view.subviews {
            if let scroll = subview as? UIScrollView {
                scroll.delaysContentTouches = false
            }
        }

        if let initial = context.coordinator.controllers[safe: currentIndex] {
            pvc.setViewControllers([initial], direction: .forward, animated: false)
        }
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        context.coordinator.parent = self

        // Forward SwiftUI view updates into the live hosting controllers.
        for (i, page) in pages.enumerated()
        where i < context.coordinator.controllers.count {
            context.coordinator.controllers[i].rootView = page
        }

        guard
            let currentVC = pvc.viewControllers?.first as? UIHostingController<Page>,
            let currentIdx = context.coordinator.controllers.firstIndex(of: currentVC),
            currentIdx != currentIndex,
            let target = context.coordinator.controllers[safe: currentIndex]
        else { return }

        let direction: UIPageViewController.NavigationDirection =
            currentIndex > currentIdx ? .forward : .reverse

        context.coordinator.isProgrammatic = true
        pvc.setViewControllers([target], direction: direction, animated: true) { _ in
            context.coordinator.isProgrammatic = false
        }
    }

    final class Coordinator: NSObject,
                             UIPageViewControllerDataSource,
                             UIPageViewControllerDelegate {
        var parent: PageViewController
        var controllers: [UIHostingController<Page>]
        var isProgrammatic = false

        init(_ parent: PageViewController) {
            self.parent = parent
            self.controllers = parent.pages.map { page in
                let host = UIHostingController(rootView: page)
                host.view.backgroundColor = .clear
                return host
            }
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard
                let host = viewController as? UIHostingController<Page>,
                let idx = controllers.firstIndex(of: host), idx > 0
            else { return nil }
            return controllers[idx - 1]
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard
                let host = viewController as? UIHostingController<Page>,
                let idx = controllers.firstIndex(of: host),
                idx < controllers.count - 1
            else { return nil }
            return controllers[idx + 1]
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard
                completed,
                let current = pvc.viewControllers?.first as? UIHostingController<Page>,
                let idx = controllers.firstIndex(of: current)
            else { return }
            // Defer to the next runloop tick to avoid mutating SwiftUI state
            // inside a UIKit delegate callback.
            DispatchQueue.main.async { [weak self] in
                self?.parent.currentIndex = idx
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
