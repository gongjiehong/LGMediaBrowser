//
//  LGMPAlbumListController.swift
//  LGMediaBrowser
//
//  Created by 龚杰洪 on 2018/6/21.
//  Copyright © 2018年 龚杰洪. All rights reserved.
//

import UIKit


public class LGAlbumListCell: UITableViewCell {
    
    weak var thumbnailImageView: UIImageView!
    weak var titleAndCountLabel: UILabel!
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public class LGMPAlbumListController: LGMPBaseViewController {
    
    private struct Reuse {
        static var LGAlbumListCell = "LGAlbumListCell"
    }
    
    weak var listTable: UITableView!
    
    var dataArray: [LGAlbumListModel] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LGLocalizedString("Albums")
        
        setupTableView()
    }
    
    func setupTableView() {
        let temp = UITableView(frame: self.view.bounds, style: UITableViewStyle.plain)
        temp.estimatedRowHeight = 0.0
        temp.estimatedSectionFooterHeight = 0.0
        temp.estimatedSectionHeaderHeight = 0.0
        temp.delegate = self
        temp.dataSource = self
        self.listTable = temp
        
        temp.register(LGAlbumListCell.self, forCellReuseIdentifier: Reuse.LGAlbumListCell)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAlbumList()
    }
    
    func fetchAlbumList() {
        DispatchQueue.utility.async { [weak self] in
            LGPhotoManager.fetchAlbumList(LGPhotoManager.ResultMediaType.all) { [weak self] (resultArray) in
                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.dataArray.removeAll()
                    weakSelf.dataArray += resultArray
                    weakSelf.listTable.reloadData()
                }
            }
        }
    }
    
}

extension LGMPAlbumListController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    }
}
