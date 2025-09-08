//
//  ContentView.swift
//  SlideMenuViewController
//
//  Created by Yuki Sasaki on 2025/09/08.
//

import SwiftUI
import CoreData
import UIKit


// 1️⃣ まず既存の UIViewController
import UIKit
import CoreData

class MyViewController: UIViewController {

    // MARK: - プロパティ
    private var slideMenuVC: SlideMenuViewController?
    private var overlayView: UIView?
    
    private var context: NSManagedObjectContext

    // MARK: - イニシャライザ
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupMenuButton()
        setupEdgePanGesture()
    }

    // MARK: - メニュー表示ボタン
    private func setupMenuButton() {
        let menuButton = UIButton(type: .system)
        menuButton.setTitle("☰", for: .normal)
        menuButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
        view.addSubview(menuButton)

        NSLayoutConstraint.activate([
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    // MARK: - 左端スワイプジェスチャー
    private func setupEdgePanGesture() {
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
    }

    @objc private func showMenu() {
        presentSlideMenu()
    }

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .began {
            presentSlideMenu()
        }
    }

    // MARK: - スライドメニュー表示
    private func presentSlideMenu() {
        // すでに表示中なら何もしない
        if slideMenuVC != nil { return }

        // ①オーバーレイ作成
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideMenu))
        overlay.addGestureRecognizer(tap)
        view.addSubview(overlay)
        overlayView = overlay

        // ②SlideMenuViewController作成（context を渡す）
        let menuVC = SlideMenuViewController(context: context)
        menuVC.view.frame = CGRect(x: -250, y: 0, width: 250, height: view.frame.height)
        addChild(menuVC)
        view.addSubview(menuVC.view)
        menuVC.didMove(toParent: self)
        slideMenuVC = menuVC

        // ③アニメーションで表示
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
            menuVC.view.frame.origin.x = 0
        }
    }

    // MARK: - スライドメニュー非表示
    @objc private func hideMenu() {
        guard let menuVC = slideMenuVC, let overlay = overlayView else { return }

        UIView.animate(withDuration: 0.3, animations: {
            menuVC.view.frame.origin.x = -250
            overlay.alpha = 0
        }, completion: { _ in
            menuVC.willMove(toParent: nil)
            menuVC.view.removeFromSuperview()
            menuVC.removeFromParent()
            overlay.removeFromSuperview()
            self.slideMenuVC = nil
            self.overlayView = nil
        })
    }
}










// 2️⃣ UIViewControllerRepresentable で SwiftUI に組み込む
struct MyViewControllerRepresentable: UIViewControllerRepresentable {

    @Environment(\.managedObjectContext) private var context

    func makeUIViewController(context: Context) -> MyViewController {
        // SwiftUI の managedObjectContext を渡す
        return MyViewController(context: self.context)
    }

    func updateUIViewController(_ uiViewController: MyViewController, context: Context) {
        // 必要に応じて更新
    }
}


// 3️⃣ SwiftUI 内で使用
struct ContentView: View {
    var body: some View {
        MyViewControllerRepresentable()
            .edgesIgnoringSafeArea(.all) // 必要ならフルスクリーン
    }
}
