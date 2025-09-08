//
//  ContentView.swift
//  SlideMenuViewController
//
//  Created by Yuki Sasaki on 2025/09/08.
//

import SwiftUI
import CoreData
import UIKit

struct SlideMenuControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .white

        let width: CGFloat = 250

        // SlideMenu
        let slideMenuVC = UIViewController()
        slideMenuVC.view.backgroundColor = .systemGray
        slideMenuVC.view.frame = CGRect(x: -width, y: 0, width: width, height: UIScreen.main.bounds.height)
        containerVC.addChild(slideMenuVC)
        containerVC.view.addSubview(slideMenuVC.view)
        slideMenuVC.didMove(toParent: containerVC)
        context.coordinator.slideMenuVC = slideMenuVC

        // オーバーレイ（背景）を準備
        let overlay = UIButton(frame: containerVC.view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        overlay.addTarget(context.coordinator, action: #selector(Coordinator.hideMenu), for: .touchUpInside)
        containerVC.view.insertSubview(overlay, belowSubview: slideMenuVC.view)
        context.coordinator.overlay = overlay

        // サンプルラベル
        let label = UILabel(frame: CGRect(x: 20, y: 100, width: 200, height: 40))
        label.text = "Slide Menu"
        slideMenuVC.view.addSubview(label)

        // UIKitボタンで開閉
        let toggleButton = UIButton(type: .system)
        toggleButton.frame = CGRect(x: 50, y: 50, width: 120, height: 50)
        toggleButton.setTitle("Toggle Menu", for: .normal)
        toggleButton.backgroundColor = .systemBlue
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.layer.cornerRadius = 8
        toggleButton.addTarget(context.coordinator, action: #selector(Coordinator.toggleMenu), for: .touchUpInside)
        containerVC.view.addSubview(toggleButton)

        // 左端からスワイプで開くジェスチャー
        let edgeSwipe = UIScreenEdgePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleEdgeSwipe(_:)))
        edgeSwipe.edges = .left
        containerVC.view.addGestureRecognizer(edgeSwipe)

        return containerVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var slideMenuVC: UIViewController?
        weak var overlay: UIButton?
        private var isShowing = false

        @objc func toggleMenu() {
            guard let menu = slideMenuVC, let overlay = overlay else { return }
            isShowing.toggle()
            UIView.animate(withDuration: 0.3) {
                menu.view.frame.origin.x = self.isShowing ? 0 : -menu.view.frame.width
                overlay.backgroundColor = UIColor.black.withAlphaComponent(self.isShowing ? 0.3 : 0.0)
            }
        }

        @objc func hideMenu() {
            guard let menu = slideMenuVC, let overlay = overlay else { return }
            isShowing = false
            UIView.animate(withDuration: 0.3) {
                menu.view.frame.origin.x = -menu.view.frame.width
                overlay.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            }
        }

        @objc func handleEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
            guard let menu = slideMenuVC, let overlay = overlay else { return }
            let translation = gesture.translation(in: gesture.view)
            let width = menu.view.frame.width

            switch gesture.state {
            case .changed:
                let x = min(max(-width + translation.x, -width), 0)
                menu.view.frame.origin.x = x
                overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3 * (1 + x / width))
            case .ended, .cancelled:
                let shouldOpen = translation.x > width / 2
                isShowing = shouldOpen
                UIView.animate(withDuration: 0.3) {
                    menu.view.frame.origin.x = shouldOpen ? 0 : -width
                    overlay.backgroundColor = UIColor.black.withAlphaComponent(shouldOpen ? 0.3 : 0.0)
                }
            default: break
            }
        }
    }
}

// SwiftUI側
struct ContentView: View {
    var body: some View {
        SlideMenuControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
