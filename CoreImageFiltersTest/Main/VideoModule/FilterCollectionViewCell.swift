//
//  FilterCollectionViewCell.swift
//  FiltersTest
//
//  Created by Yuliya on 20/09/2024.
//

import UIKit

struct FilterCollectionViewModel {
    let filterName: FilterName
}

final class FilterCollectionViewCell: UICollectionViewCell {
    
    static var identifier: String {
        return String(describing: FilterCollectionViewCell.self)
    }
    
    let textLabel = UILabel.new {
        $0.textAlignment = .center
        $0.font = UIFont.systemFont(ofSize: 16)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(textLabel)
        contentView.backgroundColor = .systemRed.withAlphaComponent(0.7)
        contentView.layer.cornerRadius = 10

        textLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(5)
        }
    }
    
    func set(_ data: FilterCollectionViewModel) {
        textLabel.text = data.filterName.rawValue
    }
}
