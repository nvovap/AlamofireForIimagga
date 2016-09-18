/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/



import UIKit
import Alamofire
//NSCameraUsageDescription
//YWNjX2NiYzliMGEzMTdlNjI4Mjo2ODQwMDI3NzdiMTQ4MGNmNWMyNDAwZTgxNzM1YTYyMQ



class ViewController: UIViewController {
  
  // MARK: - IBOutlets
  @IBOutlet var takePictureButton: UIButton!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var progressView: UIProgressView!
  @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
  
  // MARK: - Properties
  fileprivate var tags: [String]?
  fileprivate var colors: [PhotoColor]?

  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    if !UIImagePickerController.isSourceTypeAvailable(.camera) {
      takePictureButton.setTitle("Select Photo", for: UIControlState())
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    imageView.image = nil
    
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    if segue.identifier == "ShowResults" {
      guard let controller = segue.destination as? TagsColorsViewController else {
        fatalError("Storyboard mis-configuration. Controller is not of expected type TagsColorsViewController")
      }

      controller.tags = tags
      controller.colors = colors
    }
  }

  // MARK: - IBActions
  @IBAction func takePicture(_ sender: UIButton) {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = false

    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      picker.sourceType = UIImagePickerControllerSourceType.camera
    } else {
      picker.sourceType = .photoLibrary
      picker.modalPresentationStyle = .fullScreen
    }

    present(picker, animated: true, completion: nil)
  }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
      print("Info did not have the required UIImage for the Original Image")
      dismiss(animated: true, completion: nil)
      return
    }
    
    imageView.image = image
    
    takePictureButton.isHidden = true
    progressView.progress = 0.0
    progressView.isHidden = false
    activityIndicatorView.startAnimating()
    
    
    
    dismiss(animated: true, completion: nil)
    
    
    
    uploadImage(image: image, progress: { [unowned self]  (precent) in
      self.progressView.setProgress(precent, animated: true)
    }) { [unowned self] (tags, colors) in
      self.takePictureButton.isHidden = false
      self.progressView.isHidden = true
      self.activityIndicatorView.stopAnimating()
      
      self.tags = tags
      self.colors = colors
      
      DispatchQueue.main.async {
          self.performSegue(withIdentifier: "ShowResults", sender: self)
      }
    }
  }
}


//{
//  bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
//  DispatchQueue.main.async {
//    let percent = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
//    progress(percent: percent)
//  }
//  
//  upload.validate()
//  upload.responseJSON(completionHandler: { response in
//    guard response.result.
//  })


extension ViewController {
  
  func uploadImage(image: UIImage, progress: @escaping (_ percent: Float) -> Void, completion: @escaping (_ tags: [String], _ colors: [PhotoColor]) -> Void){
    
    guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
      print("Could not get JPEG representation of UIImage")
      return
    }
    
    
    Alamofire.upload(multipartFormData: { multipartFromData in multipartFromData.append(imageData, withName: "imagefile", fileName: "image.jpg", mimeType:  "image/jpeg")}, usingThreshold: 100000000, to: "http://api.imagga.com/v1/content", method: .post, headers: ["Authorization" : "Basic YWNjX2NiYzliMGEzMTdlNjI4Mjo2ODQwMDI3NzdiMTQ4MGNmNWMyNDAwZTgxNzM1YTYyMQ=="], encodingCompletion: { result in
      
      switch result {
      case .success(let upload, _, _):
        upload.uploadProgress(closure: { (progressFact) in
          
          
          DispatchQueue.main.async {
            let percent = Float(progressFact.fractionCompleted)
            progress(percent)
          }
        })
        
        upload.validate()
        upload.responseJSON(completionHandler: { (res: DataResponse<Any>) in
          guard res.result.isSuccess else {
            print("Error while uploading file: \(res.result.error?.localizedDescription)")
            
            completion([String](), [PhotoColor]())
            
            return
          }
          
          
          guard let responseJSON = res.result.value as? [String: Any],
            let uploadedFiles = responseJSON["uploaded"] as? [Any],
            let firstFile = uploadedFiles.first as? [String: Any],
            let firstFileID = firstFile["id"] as? String else {
              print("Invalid information recived from service")
              
              completion([String](), [PhotoColor]())
              
              return
          }
          
          
          print("Content uploaded with ID: \(firstFileID)")
          
          
          
          self.downloadTags(contentID: firstFileID) { tags in
            self.downloadColors(contentID: firstFileID) { colors in
              completion(tags, colors)
            }
          }
          
          
        })
      case .failure(let error):
        print(error)
      }
      
      }
    )
    
  
  }
  
  func downloadTags(contentID: String, completion: @escaping ([String]) -> Void) {
    Alamofire.request("http://api.imagga.com/v1/tagging", method: .get, parameters:  ["content": contentID], encoding: URLEncoding.default, headers:  ["Authorization" : "Basic YWNjX2NiYzliMGEzMTdlNjI4Mjo2ODQwMDI3NzdiMTQ4MGNmNWMyNDAwZTgxNzM1YTYyMQ=="]).responseJSON { (res) in
      guard res.result.isSuccess else {
        print("Error while uploading file: \(res.result.error?.localizedDescription)")
        
        completion([String]())
        
        return
      }
      
      guard let responseJSON = res.result.value as? [String: AnyObject],
        let results = responseJSON["results"] as? [AnyObject],
        let firstResult = results.first,
        let tagsAndConfidences = firstResult["tags"] as? [[String: AnyObject]] else {
        print("Invalid tag information received from service")
        completion([String]())
        return
      }
      
      
      
      let tags = tagsAndConfidences.flatMap({ dict in
         return dict["tag"] as? String
      })
      
      
      completion(tags)
      
      
    }
  }
  
  
  func downloadColors(contentID: String, completion: @escaping ([PhotoColor]) -> Void) {
    Alamofire.request("http://api.imagga.com/v1/colors", method: .get, parameters:  ["content": contentID, "extract_object_colors": NSNumber(value: 0)], encoding: URLEncoding.default, headers:  ["Authorization" : "Basic YWNjX2NiYzliMGEzMTdlNjI4Mjo2ODQwMDI3NzdiMTQ4MGNmNWMyNDAwZTgxNzM1YTYyMQ=="]).responseJSON { (response) in
        // 2.
        guard response.result.isSuccess else {
          print("Error while fetching colors: \(response.result.error)")
          completion([PhotoColor]())
          return
        }
      
        // 3.
        guard let responseJSON = response.result.value as? [String: AnyObject],
          let results = responseJSON["results"] as? [AnyObject],
          let firstResult = results.first as? [String: AnyObject],
          let info = firstResult["info"] as? [String: AnyObject],
          let imageColors = info["image_colors"] as? [[String: AnyObject]] else {
            print("Invalid color information received from service")
            completion([PhotoColor]())
            return
        }
        
        // 4.
        let photoColors = imageColors.flatMap({ (dict) -> PhotoColor? in
          guard let r = dict["r"] as? String,
            let g = dict["g"] as? String,
            let b = dict["b"] as? String,
            let closestPaletteColor = dict["closest_palette_color"] as? String else {
              return nil
          }
          return PhotoColor(red: Int(r),
                            green: Int(g),
                            blue: Int(b),
                            colorName: closestPaletteColor)
        })
        
        // 5.
        completion(photoColors)
    }
  }
  
}

