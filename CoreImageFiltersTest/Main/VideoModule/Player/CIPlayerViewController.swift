//
//  CIPlayerViewController.swift
//  FiltersTest
//
//  Created by Yuliya on 11/09/2024.
//

import AVFoundation
import SnapKit
import UIKit
import Photos

class CIPlayerViewController: UIViewController {
    
    private let videoPlayerView = UIView()
    
    private let previewImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isPlaying = false
    private var isFinishedPlaying = false
    
    private let videoURL: URL
    
    // MARK: - Init
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        invalidatePlayer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupView()
        configure(with: videoURL)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPlayerView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        invalidatePlayer()
    }
    
    // MARK: - Configure
    func configure(with url: URL?) {
        guard let url else { return }
        let item = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: item)
        previewImageView.image = videoPlayerView.getVideoThumbnailImage(fromURL: url)
    }
    
    func invalidatePlayer() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
    }
    
    // MARK: - Setup view
    private func setupView() {
        addSubviews()
        setupConstraints()
        
        setupLayers()
        configurePlayer()
        configureTapGesture()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"),
                                                                    style: .plain,
                                                                    target: self,
                                                                    action: #selector(saveVideoAction))
    }
    
    @objc private func saveVideoAction() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UISaveVideoAtPathToSavedPhotosAlbum(self.videoURL.path, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error",
                                                  message: "Access to the photo library is not allowed.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc private func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: Any?) {
        DispatchQueue.main.async {
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Saved!", message: "The video was successfully saved to your photo library.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }    
 
    private func setupLayers() {
        videoPlayerView.layer.cornerCurve = .continuous
        videoPlayerView.layer.masksToBounds = true
    }
    
    private func addSubviews() {
        view.addSubview(videoPlayerView)
        view.addSubview(previewImageView)
    }
    
    private func setupConstraints() {
        previewImageView.snp.makeConstraints {
            $0.top.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        videoPlayerView.snp.makeConstraints {
            $0.top.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    // MARK: - Config player
    private func configurePlayer() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.cornerCurve = .continuous
        playerLayer?.masksToBounds = true
        
        if let playerLayer {
            videoPlayerView.layer.addSublayer(playerLayer)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem, queue: .main) { [weak self] _ in
            guard let self = self, self.player?.currentItem != nil else {
                return
            }
            DispatchQueue.main.async {
                self.player?.seek(to: .zero)
                self.isPlaying = false
                self.isFinishedPlaying = true
                self.setupPlayerState()
            }
        }
    }
    
    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(tapAction(recognizer: )))
            videoPlayerView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func tapAction(recognizer: UITapGestureRecognizer) {
        isPlaying.toggle()
        setupPlayerState()
    }
    
    private func setupPlayerState() {
        if isPlaying {
            playPlayer()
        } else {
            pausePlayer()
        }
    }
    
    private func playPlayer() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.previewImageView.alpha = 0
        }
        player?.play()
        isFinishedPlaying = false
    }
    
    private func pausePlayer() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            if self?.isFinishedPlaying ?? false {
                self?.previewImageView.alpha = 1
            }
        }
        player?.pause()
    }
}
