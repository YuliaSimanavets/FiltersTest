//
//  CIImageViewController.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit
import SnapKit
import PhotosUI
import AVFoundation

final class CIImageViewController: UIViewController {
    weak var coordinator: CIImageCoordinator?
    private let viewModel: CIImageViewModel
    
    // MARK: - Property list
    var firstPhotoViewContainer = UIImageView.new {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.darkGray.cgColor
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    var secondPhotoViewContainer = UIImageView.new {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.darkGray.cgColor
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    private let selectButtonsStackView = UIStackView.new {
        $0.axis = .horizontal
        $0.spacing = 15
        $0.distribution = .fillEqually
    }    
    
    private let applyButtonsStackView = UIStackView.new {
        $0.axis = .horizontal
        $0.spacing = 15
        $0.distribution = .fillEqually
    }
    
    var maskImage = UIImage()
    
    private let selectFirstImageButton = CIAAddMediaButton()
    private let selectSecondImageButton = CIAAddMediaButton()
    private let addMaskButton = CIAAddMediaButton()
    
    private let applyFirstFilterButton = CIAAddMediaButton()
    private let applySecondFilterButton = CIAAddMediaButton()
    private let applyMaskButton = CIAAddMediaButton()
    
    private var isFirstImagePicking = true
    private var isSecondImagePicking = false
    private var isMediaAdded = false
    private var isMaskAdded = false
    
    var isMediaEditing = false
    
    // MARK: - Lifecycle

    init(viewModel: CIImageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setAddButtonActions()
        setApplyButtonActions()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(firstPhotoViewContainer)
        view.addSubview(secondPhotoViewContainer)
        
        view.addSubview(selectButtonsStackView)
        view.addSubview(applyButtonsStackView)
        
        selectFirstImageButton.configureButton(with: "first image")
        selectSecondImageButton.configureButton(with: "second image")
        addMaskButton.configureButton(with: "add mask")
        selectButtonsStackView.addArrangedSubviews(selectFirstImageButton, selectSecondImageButton, addMaskButton)

        applyFirstFilterButton.configureButton(with: "first filter")
        applySecondFilterButton.configureButton(with: "second filter")
        applyMaskButton.configureButton(with: "apply mask")
        applyButtonsStackView.addArrangedSubviews(applyFirstFilterButton, applySecondFilterButton, applyMaskButton)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                            target: self,
                                                            action: #selector(removePhotoAction))
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        selectButtonsStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        applyButtonsStackView.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        firstPhotoViewContainer.snp.makeConstraints {
            $0.top.equalTo(selectButtonsStackView.snp.bottom).inset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(applyButtonsStackView.snp.top).inset(-10)
        }

        secondPhotoViewContainer.snp.makeConstraints {
            $0.top.equalTo(selectButtonsStackView.snp.bottom).inset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(applyButtonsStackView.snp.top).inset(-10)
        }
    }
    
    // MARK: - Add button

    private func setAddButtonActions() {
                
        selectFirstImageButton.buttonActionCallback = { [weak self] in
            guard let self else { return }
            self.isMediaAdded = true
            self.isFirstImagePicking = true
            self.isSecondImagePicking = false
            self.isMaskAdded = false
            
            self.configureImagePicker()
        }
        
        selectSecondImageButton.buttonActionCallback = { [weak self] in
            guard let self else { return }
            self.isMediaAdded = true
            self.isFirstImagePicking = false
            self.isSecondImagePicking = true
            self.isMaskAdded = false
            
            self.configureImagePicker()
        }
       
        addMaskButton.buttonActionCallback = { [weak self] in
            guard let self else { return }
            self.isMaskAdded = true
            self.isFirstImagePicking = false
            self.isSecondImagePicking = false
            
            self.configureImagePicker()
        }
    }
    
    // MARK: - Play button
    
    private func setApplyButtonActions() {
        
        applyFirstFilterButton.buttonActionCallback = { [weak self] in
            guard let self, !(firstPhotoViewContainer.image == nil) else { return }
            let filteredImage = self.viewModel.applyFirstFilter(for: firstPhotoViewContainer)
            firstPhotoViewContainer.image = nil
            firstPhotoViewContainer.image = filteredImage
        }
        
        applySecondFilterButton.buttonActionCallback = { [weak self] in
            guard let self, !(secondPhotoViewContainer.image == nil) else { return }
            let filteredImage = self.viewModel.applySecondFilter(for: secondPhotoViewContainer)
            secondPhotoViewContainer.image = nil
            secondPhotoViewContainer.image = filteredImage
        }

        applyMaskButton.buttonActionCallback = { [weak self] in
            guard let self, !(firstPhotoViewContainer.image == nil), !isMaskAdded else { return }
            let filteredImage = self.viewModel.applyMask(with: firstPhotoViewContainer, and: maskImage)
            firstPhotoViewContainer.image = nil
            firstPhotoViewContainer.image = filteredImage
        }
    }
    
    private func configureImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    @objc
    func removePhotoAction() {
            firstPhotoViewContainer.image = nil
            secondPhotoViewContainer.image = nil
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CIImageViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
            DispatchQueue.main.async {
                guard let self = self, let image = image as? UIImage else { return }
                
                if self.isFirstImagePicking {
                    DispatchQueue.main.async {
                        self.firstPhotoViewContainer.image = image
                    }
                    self.isFirstImagePicking = false
                }
                else if self.isMaskAdded {
                    self.maskImage = image
                    self.isMaskAdded = false
                }
                else if self.isSecondImagePicking {
                    DispatchQueue.main.async {
                        self.secondPhotoViewContainer.image = image
                    }
                }
            }
        }
    }
}
