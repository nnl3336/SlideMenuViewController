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

        // SlideMenu
        let slideMenuVC = UIViewController()
        slideMenuVC.view.backgroundColor = .systemGray
        let width: CGFloat = 250
        slideMenuVC.view.frame = CGRect(x: -width, y: 0, width: width, height: UIScreen.main.bounds.height)
        containerVC.addChild(slideMenuVC)
        containerVC.view.addSubview(slideMenuVC.view)
        slideMenuVC.didMove(toParent: containerVC)
        context.coordinator.slideMenuVC = slideMenuVC

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

        return containerVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // UIKit側で完結するのでここは空でもOK
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var slideMenuVC: UIViewController?
        private var isShowing = false

        @objc func toggleMenu() {
            guard let menu = slideMenuVC else { return }
            isShowing.toggle()
            let width: CGFloat = 250
            UIView.animate(withDuration: 0.3) {
                menu.view.frame.origin.x = self.isShowing ? 0 : -width
            }
        }
    }
}

// SwiftUI側の呼び出し例
struct ContentView: View {
    var body: some View {
        SlideMenuControllerRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
