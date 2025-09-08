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
    private let menuItems = ["Home", "Profile", "Settings"]
    
    var flatData: [FolderEntity] = []
    var isHideMode = false // ← トグルで切り替え
    
    var selectedFolders: Set<FolderEntity> = []

    func visibleData() -> [FolderEntity] {
        if isHideMode {
            return flatData.filter { !$0.isHide }
        } else {
            return flatData
        }
    }
    
    var viewContext: NSManagedObjectContext!
    
    var fetchedResultsController: NSFetchedResultsController<FolderEntity>!

    //***
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    //***

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleData().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = visibleData()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! AccordionCell
        
        cell.textLabel?.text = item.folderName
        cell.arrowImageView.isHidden = (item.children?.count ?? 0) == 0
        cell.arrowImageView.transform = item.isOpen ? CGAffineTransform(rotationAngle: .pi/2) : .identity
        
        // 選択ハイライト
        if selectedFolders.contains(item) {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3) // systemBlueに半透明
        } else {
            cell.backgroundColor = .clear
        }
        
        cell.onArrowTapped = { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }
            item.isOpen.toggle()
            try? self.viewContext.save()
            self.flatData = self.flatten(self.fetchedResultsController.fetchedObjects ?? [])
            
            UIView.animate(withDuration: 0.25) {
                cell.arrowImageView.transform = item.isOpen ? CGAffineTransform(rotationAngle: .pi/2) : .identity
            }
            
            self.tableView.reloadData()
        }
        
        return cell
    }
    
    func flatten(_ items: [FolderEntity]) -> [FolderEntity] {
            var result: [FolderEntity] = []
            
            for item in items {
                result.append(item)
                
                // children を再帰的に平坦化
                if let children = item.children?.allObjects as? [FolderEntity], !children.isEmpty {
                    result.append(contentsOf: flatten(children))
                }
            }
            
            return result
        }
    
    func flattenWithSearch(_ items: [FolderEntity], keyword: String?) -> [FolderEntity] {
        var result: [FolderEntity] = []
        
        for item in items {
            let children = (item.children?.allObjects as? [FolderEntity]) ?? []
            let filteredChildren = flattenWithSearch(children, keyword: keyword)
            
            let matchSelf = keyword.map { item.folderName?.localizedCaseInsensitiveContains($0) ?? false } ?? true
            
            if matchSelf || !filteredChildren.isEmpty {
                if !filteredChildren.isEmpty {
                    item.isOpen = true  // 子がマッチしたら親を展開
                }
                result.append(item)
                result.append(contentsOf: filteredChildren)
            }
        }
        
        return result
    }

    func setupFetchedResultsController() {
        let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "folderName", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        try? fetchedResultsController.performFetch()
        flatData = flatten(fetchedResultsController.fetchedObjects ?? [])
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
class MyViewController: UIViewController {

    private var slideMenuVC: SlideMenuViewController?
    private var overlayView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // 左上ボタン
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

        // 左端スワイプジェスチャー
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
    }

    // ボタンからも呼ぶ
    @objc private func showMenu() {
        presentSlideMenu()
    }

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .began {
            presentSlideMenu()
        }
    }

    private func presentSlideMenu() {
        if slideMenuVC != nil { return } // すでに表示中なら何もしない

        // オーバーレイ
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideMenu))
        overlay.addGestureRecognizer(tap)
        view.addSubview(overlay)
        overlayView = overlay

        // SlideMenu
        let menuVC = SlideMenuViewController()
        menuVC.view.frame = CGRect(x: -250, y: 0, width: 250, height: view.frame.height)
        addChild(menuVC)
        view.addSubview(menuVC.view)
        menuVC.didMove(toParent: self)
        slideMenuVC = menuVC

        // アニメーション
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
            menuVC.view.frame.origin.x = 0
        }
    }

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
    
    // UIViewController を生成
    func makeUIViewController(context: Context) -> MyViewController {
        return MyViewController()
    }
    
    // UIViewController 更新処理（必要に応じて）
    func updateUIViewController(_ uiViewController: MyViewController, context: Context) {
        // SwiftUI の状態が変わったときに UIViewController を更新
    }
}

// 3️⃣ SwiftUI 内で使用
struct ContentView: View {
    var body: some View {
        MyViewControllerRepresentable()
            .edgesIgnoringSafeArea(.all) // 必要ならフルスクリーン
    }
}
