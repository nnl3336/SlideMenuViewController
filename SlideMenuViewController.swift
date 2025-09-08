//
//  SlideMenuViewController.swift
//  SlideMenuViewController
//
//  Created by Yuki Sasaki on 2025/09/08.
//

// 1️⃣ SlideMenu本体
import SwiftUI
import UIKit
import CoreData

class SlideMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView()
    var flatData: [FolderEntity] = []
    var viewContext: NSManagedObjectContext
    var selectedFolders: Set<FolderEntity> = []
    
    lazy var fetchedResultsController: NSFetchedResultsController<FolderEntity> = {
        let fetchRequest: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "folderName", ascending: true)]
        
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? frc.performFetch()
        return frc
    }()

    
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
        
        // 子フォルダがある場合のみ > を表示
        if let children = item.children, children.count > 0 {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = selectedFolders.contains(item) ? .checkmark : .none
        }
        
        return cell
    }

    
    
    // MARK: - コンテキストメニュー　.contextMenu
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        
        let item = flatData[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else {
                   return UIMenu(title: "", children: [])
               }
            
            // MARK: - フォルダ追加アクション
            let addFolder = UIAction(title: "フォルダ追加", image: UIImage(systemName: "folder.badge.plus")) { _ in
                let alert = UIAlertController(title: "フォルダ名を入力", message: nil, preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.placeholder = "新しいフォルダ名"
                }
                let addAction = UIAlertAction(title: "追加", style: .default) { _ in
                    if let folderName = alert.textFields?.first?.text, !folderName.isEmpty {
                        self.addChildFolder(to: item, name: folderName)
                    }
                }
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
                alert.addAction(addAction)
                alert.addAction(cancelAction)
                if let vc = self.presentingViewController ?? self as? UIViewController {
                    vc.present(alert, animated: true)
                }
            }
            
            // MARK: - 選択/トグルアクション
            let selectAction = UIAction(
                title: self.selectedFolders.contains(item) ? "選択解除" : "選択",
                image: UIImage(systemName: self.selectedFolders.contains(item) ? "checkmark.circle.fill" : "checkmark.circle")
            ) { _ in
                guard let index = self.flatData.firstIndex(of: item) else { return }
                let indexPath = IndexPath(row: index, section: 0)

                // toggleSelection で selectedItems と toolbarState を統一
                self.toggleSelection(at: indexPath, in: self.tableView)
            }


            
            // MARK: - 削除アクション
            let delete = UIAction(title: "削除", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.delete(item)
            }
            
            // MARK: - メニューにまとめる
            return UIMenu(title: "", children: [addFolder, selectAction, delete])
        }
    }
    
    
    
    // MARK: - 子フォルダ追加
    func addChildFolder(to parent: FolderEntity
                        , name: String) {
        let newEntity = FolderEntity(context: viewContext)
        newEntity.folderName = name  // ここで引数 name を使う
        newEntity.isOpen = false
        parent.addToChildren(newEntity)
        newEntity.parent = parent
        parent.isOpen = true

        do {
            try viewContext.save()
            flatData = flatten(fetchedResultsController.fetchedObjects ?? [])
            tableView.reloadData()
            if let index = flatData.firstIndex(of: newEntity) {
                tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
            }
        } catch {
            print("保存失敗: \(error)")
        }
    }
    
    // MARK: - 選択トグル
    func toggleSelection(at indexPath: IndexPath, in tableView: UITableView) {
        let folder = flatData[indexPath.row]
        
        if selectedFolders.contains(folder) {
            selectedFolders.remove(folder)
        } else {
            selectedFolders.insert(folder)
        }
        
        // セルを更新してチェックマーク表示を変える場合
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = selectedFolders.contains(folder) ? .checkmark : .none
        }
    }

    
    // MARK: - 階層をフラット化（展開状態を考慮）
    func flatten(_ items: [FolderEntity]) -> [FolderEntity] {
        var result: [FolderEntity] = []
        for item in items {
            result.append(item)
            if item.isOpen,
               let children = item.children?.allObjects as? [FolderEntity] {
                result.append(contentsOf: flatten(children))
            }
        }
        return result
    }
    
    // MARK: - セルタップ
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // ✅ 空ならタップでは選択できない
        guard !selectedFolders.isEmpty else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        // 通常のトグル処理
        toggleSelection(at: indexPath, in: tableView)
        
        // デバッグ用プリント
        //    print("選択されたフォルダ: \(item.name)")  // 例: item に name プロパティがある場合
        print("現在の selectedFolders: \(self.selectedFolders.map { $0.folderName ?? ""})")
        
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
