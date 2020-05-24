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
    
    
    var playing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nowPlaying.text = GlobalVar.nowplaying
        getData(from: URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.albumArt.image = UIImage(data: data)
                self.behindCover.image = UIImage(data: data)
            }
        }
        
        audioPlayer(url: GlobalVar.nowplayingurl)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        player?.pause()
        player = nil
        playing = false
        playPause.setImage(UIImage(named: "play"), for: .normal)
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
        UIApplication.shared.open(url)
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
                        self.playPause.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        },
                       completion: { _ in
                        UIView.animate(withDuration: 0.1) {
                            self.playPause.transform = CGAffineTransform.identity
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
