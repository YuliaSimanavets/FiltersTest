//
//  CIAAddMediaButton.swift
//  CoreImageTest
//
//  Created by Yuliya on 23/08/2024.
//

import UIKit

final class CIAAddMediaButton: UIButton {
    
    var buttonActionCallback: (() -> Void)?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure
    func configureButton(with title: String) {
        setTitle(title, for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .systemRed.withAlphaComponent(0.7)
        layer.cornerRadius = 15
        titleLabel?.font = .systemFont(ofSize: 14)
        addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    }
    
    @objc private func buttonAction() {
        buttonActionCallback?()
    }
}
