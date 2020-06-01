//
//  AlbumViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 22.05.20.
//  Copyright © 2020 ptgms. All rights reserved.
//

import UIKit
import SwiftSoup

class AlbumViewController: UIViewController {

    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var trackAmount: UILabel!
    @IBOutlet weak var navigControl: UINavigationItem!
    @IBOutlet weak var avaibleFormats: UILabel!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var downloadAll: UIButton!
    @IBOutlet weak var gatherLinkProg: UILabel!
    @IBOutlet weak var gatherLinkBar: UIProgressView!
    @IBOutlet weak var gatherLinkPanel: UIView!
    
    @IBOutlet weak var backgroundVFX: UIVisualEffectView!
    @IBOutlet weak var buttonGroup: UIVisualEffectView!
    @IBOutlet weak var shareAlbumButton: UIVisualEffectView!
    @IBOutlet weak var addFavButton: UIVisualEffectView!
    @IBOutlet weak var addFavText: UILabel!
    
    
    var currentTr = 0
    var recdata = ""
    //var count = 0
    var total = GlobalVar.trackURL.count
    var image: Data = Data()
    
    var tapped = 0
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        albumName.text = GlobalVar.AlbumName
        self.albumCover.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        trackAmount.text = "Contains " + String(GlobalVar.tracks.count) + " Tracks"
        navigControl.title = GlobalVar.AlbumName
        currentTr = 0
        gatherLinkPanel.isHidden = true
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHappened))
        albumCover.addGestureRecognizer(recognizer)
        
        let recognizer2 = UITapGestureRecognizer(target: self, action: #selector(backDropPressed))
        backgroundVFX.addGestureRecognizer(recognizer2)
        
        
        
        
        var avaible = "Available Formats: "
        
        if (GlobalVar.flac) {
            avaible += "FLAC "
        }
        if (GlobalVar.mp3){
            avaible += "MP3 "
        }
        if (GlobalVar.ogg){
            avaible += "OGG "
        }
        
        avaibleFormats.text = avaible
        
        print(GlobalVar.coverURL)
        do {
            getData(from: URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? URL(string: GlobalVar.coverURL[0].addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent )
                print("Download Finished")
                DispatchQueue.main.async {
                    self.albumCover.image = UIImage(data: data)
                    self.image = data
                }
            }
        }
        
        buttonGroup.layer.masksToBounds = false
        buttonGroup.layer.cornerRadius = 8
        buttonGroup.clipsToBounds = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if (GlobalVar.fav_link.contains(GlobalVar.album_url!.absoluteString)) {
            addFavText.text = "Remove from Favorites"
        } else {
            addFavText.text = "Add to Favorites"
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    @IBAction func viewButton(_ sender: Any) {
        let url = GlobalVar.album_url
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url!)
        } else {
            UIApplication.shared.openURL(url!)
        }
    }
    
    @IBAction func downloadAllPressed(_ sender: Any) {
        currentTr = 0
        let alert = UIAlertController(title: "Question", message: "As what format do you want to save the file?", preferredStyle: .alert)
        if (GlobalVar.mp3) {
            alert.addAction(UIAlertAction(title: "MP3", style: .default, handler: { action in
                GlobalVar.download_type = ".mp3"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }))
        }
        if (GlobalVar.flac) {
            alert.addAction(UIAlertAction(title: "FLAC", style: .default, handler: { action in
                GlobalVar.download_type = ".flac"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }))
        }
        if (GlobalVar.ogg) {
            alert.addAction(UIAlertAction(title: "ogg", style: .default, handler: { action in
                GlobalVar.download_type = ".ogg"
                self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.trackURL, name: GlobalVar.tracks)
            }))
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func initDownloadAll(type: String, toDownload: [String], name: [String]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let batchDownload = storyboard.instantiateViewController(withIdentifier: "batchDownload")
        print("PRE-COUNT: " + String(GlobalVar.trackURL.count))
        self.downloadAll.setTitle("Gathering direct links...", for: .normal)
        gatherLinkBar.progress = 0.0
        self.gatherLinkPanel.isHidden = false
        let completed_url = URL(string: "https://downloads.khinsider.com" + toDownload[currentTr])!
        let task = URLSession.shared.dataTask(with: completed_url) {(data, response, error) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!
                    
                    for link in try! link.select("a") {
                        let url_prev = try! link.attr("href")
                        if (url_prev.hasSuffix(type)) {
                            print(url_prev)
                            self.currentTr += 1
                            GlobalVar.download_queue.append(URL(string: url_prev)!)
                            self.gatherLinkProg.text = "Gathering direct links:" + String(self.currentTr) + " / " + String(GlobalVar.trackURL.count)
                            self.gatherLinkBar.progress = Float(GlobalVar.trackURL.count / GlobalVar.download_queue.count)
                            if (GlobalVar.download_queue.count == GlobalVar.trackURL.count) {
                                self.gatherLinkPanel.isHidden = true
                                print(GlobalVar.download_queue)
                                self.downloadAll.setTitle("Download all Tracks", for: .normal)
                                self.gatherLinkPanel.alpha = 0.0
                                self.navigationController?.pushViewController(batchDownload, animated: true)
                                break
                            }
                            self.initDownloadAll(type: type, toDownload: toDownload, name: name)
                        } else {
                            print("Invalid type!")
                        }
                    }
                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
    @objc func longPressHappened(gestureRecognizer : UILongPressGestureRecognizer) {
        print("yes")
        if (gestureRecognizer.state == .began) {
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                if (tapped != 1) {
                    generator.impactOccurred()
                }
            }
            backgroundVFX.isHidden = false
            backgroundVFX.alpha = 0.0
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundVFX.alpha = 1.0
                self.albumCover.transform = CGAffineTransform.identity
            })
            
        } else if (gestureRecognizer.state == .ended) {
            shareAlbumButton.effect = UIBlurEffect(style: .light)
            addFavButton.effect = UIBlurEffect(style: .light)
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundVFX.alpha = 0.0
                self.albumCover.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { _ in
                self.backgroundVFX.isHidden = true
            })
            
            switch tapped {
            case 1:
                let items: [Any] = ["Check out this Album from Khinsider!\n" + GlobalVar.album_url!.absoluteString]
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                present(ac, animated: true)
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
            let point = gestureRecognizer.location(in: buttonGroup)
            
            if (shareAlbumButton.frame.contains(point)) {
                shareAlbumButton.effect = UIBlurEffect(style: .extraLight)
                addFavButton.effect = UIBlurEffect(style: .light)
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    if (tapped != 1) {
                        generator.impactOccurred()
                    }
                }
                tapped = 1
            } else if (addFavButton.frame.contains(point)) {
                shareAlbumButton.effect = UIBlurEffect(style: .light)
                addFavButton.effect = UIBlurEffect(style: .extraLight)
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    if (tapped != 2) {
                        generator.impactOccurred()
                    }
                }
                tapped = 2
            } else {
                shareAlbumButton.effect = UIBlurEffect(style: .light)
                addFavButton.effect = UIBlurEffect(style: .light)
                tapped = 0
            }
        }
        
    }
    
    @objc func backDropPressed(gestureRecognizer : UITapGestureRecognizer) {
        backgroundVFX.isHidden = true
        shareAlbumButton.isHidden = true
        addFavButton.isHidden = true
    }
    
    @objc func sharePressed(_ sender: Any) {
        let items: [Any] = ["Check out this Album from Khinsider!\n" + GlobalVar.album_url!.absoluteString]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    
}

@IBDesignable
extension UIVisualEffectView {
    // Shadow
    @IBInspectable var shadow: Bool {
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addShadow()
            }
        }
    }
    
    fileprivate func addShadow(shadowColor: CGColor = UIColor.black.cgColor, shadowOffset: CGSize = CGSize(width: 3.0, height: 3.0), shadowOpacity: Float = 0.35, shadowRadius: CGFloat = 5.0) {
        let layer = self.layer
        layer.masksToBounds = false
        
        layer.shadowColor = shadowColor
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
        layer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.cornerRadius).cgPath
        
        let backgroundColor = self.backgroundColor?.cgColor
        self.backgroundColor = nil
        layer.backgroundColor =  backgroundColor
    }
    
    
    // Corner radius
    @IBInspectable var circle: Bool {
        get {
            return layer.cornerRadius == self.bounds.width*0.5
        }
        set {
            if newValue == true {
                self.cornerRadius = self.bounds.width*0.5
            }
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    
    // Borders
    // Border width
    @IBInspectable
    public var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        
        get {
            return layer.borderWidth
        }
    }
    
    // Border color
    @IBInspectable
    public var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        
        get {
            if let borderColor = layer.borderColor {
                return UIColor(cgColor: borderColor)
            }
            return nil
        }
    }
}
