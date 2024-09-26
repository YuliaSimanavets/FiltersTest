//
//  CIVideoPlayerViewController.swift
//  CoreImageTest
//
//  Created by Yuliya on 27/08/2024.
//

import UIKit
import SnapKit
import PhotosUI
import AVFoundation
import AVKit

final class CIVideoPlayerViewController: UIViewController {
    weak var coordinator: CIVideoPlayerCoordinator?
    private let viewModel: CIVideoPlayerViewModel
    
    // MARK: - Property list
    
    private let activityIndicator = UIActivityIndicatorView()
    
    private let filtersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
            
    private var filtersArray: [FilterCollectionViewModel] = []
    private var selectedFilter: FilterName = .vhs
    
    // MARK: - Lifecycle

    init(viewModel: CIVideoPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(activityIndicator)
        
        title = "Select filter"
        
        setupCollectionView()
        setupActivityIndicator()
        setupConstraints()
    }
    
    private func setupCollectionView() {
        view.addSubview(filtersCollectionView)

        filtersArray = viewModel.getAllFilters()
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
        
        filtersCollectionView.register(FilterCollectionViewCell.self, 
                                       forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
    }
    
    private func setupActivityIndicator() {
        activityIndicator.color = .systemRed
        activityIndicator.style = .large
        activityIndicator.hidesWhenStopped = true
    }
    
    private func setupConstraints() {
        filtersCollectionView.snp.makeConstraints {
            $0.top.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func applyFilter(by selectedIndex: IndexPath) {
        selectedFilter = filtersArray[selectedIndex.item].filterName
        showLoadingState()
        configureImagePicker()
    }
    
    private func configureImagePicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .videos
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }

    private func openPlayerVC(with url: URL) {
        let playerViewController = CIPlayerViewController(videoURL: url)
        navigationController?.pushViewController(playerViewController, animated: true)
    }
    
    private func showLoadingState() {
        activityIndicator.startAnimating()
        filtersCollectionView.isHidden = true
    }
    
    private func hideLoadingState() {
        activityIndicator.stopAnimating()
        filtersCollectionView.isHidden = false
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CIVideoPlayerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty
        else {
            self.hideLoadingState()
            return
        }
        
        let itemProviders = results.map(\.itemProvider)
        
        for itemProvider in itemProviders {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
                    guard let self = self, let url = url else {
                        DispatchQueue.main.async {
                            self?.hideLoadingState()
                        }
                        return
                    }
                    
                    let fileManager = FileManager.default
                    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                    
                    if !fileManager.fileExists(atPath: destinationURL.path) {
                        do {
                            try fileManager.copyItem(at: url, to: destinationURL)
                        } catch {
                            print("Error copying video file: \(error)")
                            DispatchQueue.main.async {
                                self.hideLoadingState()
                            }
                            return
                        }
                    }
                    Task {
                        if let preparedURL = await self.viewModel.preparedVideo(by: destinationURL, filterID: self.selectedFilter) {
                            DispatchQueue.main.async {
                                self.openPlayerVC(with: preparedURL)
                                self.hideLoadingState()
                            }
                        } else {
                            DispatchQueue.main.async {
                                print("Error preparing video")
                                self.hideLoadingState()
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.hideLoadingState()
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension CIVideoPlayerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return filtersArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCollectionViewCell.identifier,
                                                            for: indexPath) as?  FilterCollectionViewCell
        else { return UICollectionViewCell() }
        cell.set(filtersArray[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        applyFilter(by: indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CIVideoPlayerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, 
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }
}
