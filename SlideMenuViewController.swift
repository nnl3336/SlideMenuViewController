//
//  SlideMenuViewController.swift
//  SlideMenuViewController
//
//  Created by Yuki Sasaki on 2025/09/08.
//

import SwiftUI

// 1️⃣ SlideMenu本体
class SlideMenuViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray

        let label = UILabel(frame: CGRect(x: 20, y: 100, width: 200, height: 40))
        label.text = "Slide Menu"
        view.addSubview(label)
    }
}
