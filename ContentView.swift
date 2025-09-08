//
//  ContentView.swift
//  SlideMenuViewController
//
//  Created by Yuki Sasaki on 2025/09/08.
//

import SwiftUI
import CoreData
import UIKit

import UIKit

class SlideMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView()
    var flatData: [FolderEntity] = []
    var viewContext: NSManagedObjectContext
    var selectedFolders: Set<FolderEntity> = []
    
    init(context: NSManagedObjectContext) {
            self.viewContext = context
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6

        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50), // ボタン分
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Folder追加ボタン
        let addButton = UIButton(type: .system)
        addButton.setTitle("＋ Folder", for: .normal)
        addButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addFolderTapped), for: .touchUpInside)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    // MARK: - ボタンアクション
    @objc private func addFolderTapped() {
        let alert = UIAlertController(title: "新しいフォルダ", message: "フォルダ名を入力してください", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "フォルダ名"
        }

        let addAction = UIAlertAction(title: "追加", style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let newFolder = FolderEntity(context: self.viewContext)
            newFolder.folderName = name
            newFolder.isOpen = false
            newFolder.isHide = false

            try? self.viewContext.save()
            self.flatData.append(newFolder)
            self.tableView.reloadData()
        }

        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        flatData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = flatData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.folderName
        return cell
    }
}

class AccordionCell: UITableViewCell {
    let arrowImageView = UIImageView()
    var onArrowTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupArrow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupArrow() {
        let arrowContainer = UIView()
        arrowContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(arrowContainer)

        arrowContainer.addSubview(arrowImageView)
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .gray

        // arrowImageView の位置だけ指定
        NSLayoutConstraint.activate([
            arrowImageView.centerYAnchor.constraint(equalTo: arrowContainer.centerYAnchor),
            arrowImageView.centerXAnchor.constraint(equalTo: arrowContainer.centerXAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        // arrowContainer の位置とタップ領域を広くする
        NSLayoutConstraint.activate([
            arrowContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowContainer.widthAnchor.constraint(equalToConstant: 44),  // 推奨44pt以上
            arrowContainer.heightAnchor.constraint(equalToConstant: 44)
        ])

        arrowContainer.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(arrowTapped))
        arrowContainer.addGestureRecognizer(tap)
    }


    @objc private func arrowTapped(_ sender: UITapGestureRecognizer) {
        onArrowTapped?()
    }
}


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
