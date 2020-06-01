//
//  PlayerViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import AVKit

class PlayerViewController: UIViewController {

    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var nowPlaying: UILabel!
    @IBOutlet weak var playPause: UIButton!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var behindCover: UIImageView!
    
    @IBOutlet weak var currentProg: UILabel!
    @IBOutlet weak var duration: UILabel!
    
    
    @IBOutlet weak var saveGroupFX: UIVisualEffectView!
    @IBOutlet weak var saveButton: UILabel!
    @IBOutlet weak var saveBackDropFX: UIVisualEffectView!
    @IBOutlet weak var saveButtonBackground: UIVisualEffectView!
    @IBOutlet weak var addFavButton: UIVisualEffectView!
    @IBOutlet weak var addFavText: UILabel!
    
    
    var playing = false
    var playable = false
    var currentplay = ""
    
    var tapped = 0
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.albumArt.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        saveGroupFX.layer.masksToBounds = false
        saveGroupFX.layer.cornerRadius = 8
        saveGroupFX.clipsToBounds = true
        
        if (GlobalVar.nowplaying == "") {
            GlobalVar.nowplaying = "Nothing playing!"
            GlobalVar.coverURL.append("https://i.ibb.co/cgRJ97N/unknown.png")
            playable = false
        } else {
            playable = true
        }
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHappened))
        albumArt.addGestureRecognizer(recognizer)
        
        let recognizer2 = UITapGestureRecognizer(target: self, action: #selector(backDropPressed))
        saveBackDropFX.addGestureRecognizer(recognizer2)
        
        let recognizer3 = UILongPressGestureRecognizer(target: self, action: #selector(saveButtonPress))
        recognizer3.minimumPressDuration = 0.1
        saveButtonBackground.addGestureRecognizer(recognizer3)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (GlobalVar.nowplayingurl != "") {
            playable = true
        }
        
        if (playable == true && currentplay != GlobalVar.nowplayingurl) {
            player = nil
            audioPlayer(url: GlobalVar.nowplayingurl)
            currentplay = GlobalVar.nowplayingurl
            getData(from: URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent)
                print("Download Finished")
                DispatchQueue.main.async {
                    self.albumArt.image = UIImage(data: data)
                    self.behindCover.image = UIImage(data: data)
                }
            }
            if (GlobalVar.fav_link.contains(GlobalVar.album_url!.absoluteString)) {
                addFavText.text = "Remove from Favorites"
            } else {
                addFavText.text = "Add to Favorites"
            }
        }
        nowPlaying.text = GlobalVar.nowplaying
    }
    

    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    @objc func playerItemDidReachEnd(notification: NSNotification) {
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    // Remove Observer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func openInSafari(_ sender: Any) {
        let url = URL(string: GlobalVar.nowplayingurl)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    var player: AVPlayer?
    func audioPlayer(url: String) {
        do {
            AVAudioSession.sharedInstance()
            player = AVPlayer(url: URL.init(string: url)!)
            player?.play()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerItemDidReachEnd),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: nil)
            playing = true
            playPause.setImage(UIImage(named: "pause"), for: .normal)
            self.duration.text = self.player?.currentItem?.asset.duration.positionalTime
            player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/30.0, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { time in
                let duration = CMTimeGetSeconds((self.player?.currentItem?.asset.duration)!)
                self.progress.value = Float((CMTimeGetSeconds(time) / duration))
                self.currentProg.text = time.positionalTime
            }
        }
    }
    
    @IBAction func playPausePressed(_ sender: Any) {
        UIView.animate(withDuration: 0.1,
                       animations: {
                        self.playPause.transform = CGAffineTransform.identity
        },
                       completion: { _ in
                        UIView.animate(withDuration: 0.1) {
                            self.albumArt.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        }
        })
        if (playing == true) {
            playing = false
            playPause.setImage(UIImage(named: "play"), for: .normal)
            player?.pause()
        } else {
            playing = true
            playPause.setImage(UIImage(named: "pause"), for: .normal)
            player?.play()
        }
    }
    @objc func longPressHappened(gestureRecognizer : UILongPressGestureRecognizer) {
        if (GlobalVar.nowplayingurl == "") {
            return
        }
        if (gestureRecognizer.state == .began) {
            saveButtonBackground.effect = UIBlurEffect(style: .light)
            addFavButton.effect = UIBlurEffect(style: .light)
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                if (tapped != 1) {
                    generator.impactOccurred()
                }
            }
            saveBackDropFX.isHidden = false
            saveButton.isHidden = false
            saveBackDropFX.alpha = 0.0
            UIView.animate(withDuration: 0.2, animations: {
                self.saveBackDropFX.alpha = 1.0
                self.albumArt.transform = CGAffineTransform.identity
            })
            
        } else if (gestureRecognizer.state == .ended) {
            UIView.animate(withDuration: 0.2, animations: {
                self.saveBackDropFX.alpha = 0.0
                self.albumArt.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { _ in
                self.saveBackDropFX.isHidden = true
            })
            saveBackDropFX.isHidden = true
            saveButton.isHidden = true
            switch tapped {
            case 1:
                if let pickedImage = albumArt.image {
                    UIImageWriteToSavedPhotosAlbum(pickedImage, self, nil, nil)
                }
            case 2:
                if (GlobalVar.fav_name.contains(GlobalVar.AlbumName)) {
                    let remove = GlobalVar.fav_name.firstIndex(of: GlobalVar.AlbumName)!
                    GlobalVar.fav_name.remove(at: remove)
                    GlobalVar.fav_link.remove(at: remove)
                    addFavText.text = "Add to Favorites"
                } else {
                    GlobalVar.fav_name.append(GlobalVar.AlbumName)
                    GlobalVar.fav_link.append(GlobalVar.album_url?.absoluteString ?? "")
                    addFavText.text = "Remove from Favorites"
                }
                print(GlobalVar.fav_name)
                defaults.set(GlobalVar.fav_name, forKey: "fav_name")
                defaults.set(GlobalVar.fav_link, forKey: "fav_link")
            default:
                return
            }
        } else if (gestureRecognizer.state) == .changed {
            let point = gestureRecognizer.location(in: saveGroupFX)
            
            if (saveButtonBackground.frame.contains(point)) {
                saveButtonBackground.effect = UIBlurEffect(style: .extraLight)
                addFavButton.effect = UIBlurEffect(style: .light)
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    if (tapped != 1) {
                        generator.impactOccurred()
                    }
                }
                tapped = 1
            } else if (addFavButton.frame.contains(point)) {
                saveButtonBackground.effect = UIBlurEffect(style: .light)
                addFavButton.effect = UIBlurEffect(style: .extraLight)
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    if (tapped != 2) {
                        generator.impactOccurred()
                    }
                }
                tapped = 2
            } else {
                saveButtonBackground.effect = UIBlurEffect(style: .light)
                addFavButton.effect = UIBlurEffect(style: .light)
                tapped = 0
            }
        }
        
    }
    
    @objc func backDropPressed(gestureRecognizer : UITapGestureRecognizer) {
        saveBackDropFX.isHidden = true
        saveButton.isHidden = true
        saveButtonBackground.isHidden = true
    }
    
    @objc func saveButtonPress(gesture: UILongPressGestureRecognizer) {
        print(gesture)
    }
    

}

extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
