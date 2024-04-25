

import UIKit
import PhotosUI
import ParseSwift

class PostFeedViewController: UIViewController, PHPickerViewControllerDelegate {
    private var pickedImage: UIImage?
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {return}
        
        provider.loadObject(ofClass: UIImage.self) {[weak self] object, error in
            guard let image = object as? UIImage else {
                self?.showAlert()
                return
            }
            
            if let error = error {
                self?.showAlert(description: "An error occured: \(error.localizedDescription)")
                return
            } else {
                DispatchQueue.main.async {
                    self?.previewImageView.image = image
                    
                    self?.pickedImage = image
                }
            }
        }
    }
    
    @IBAction func onTakePhotoTapped(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌📷 Camera not available")
            return
        }

        // Instantiate the image picker
        let imagePicker = UIImagePickerController()

        // Shows the camera (vs the photo library)
        imagePicker.sourceType = .camera

        // Allows user to edit image within image picker flow (i.e. crop, etc.)
        // If you don't want to allow editing, you can leave out this line as the default value of `allowsEditing` is false
        imagePicker.allowsEditing = true

        // The image picker (camera in this case) will return captured photos via it's delegate method to it's assigned delegate.
        // Delegate assignee must conform and implement both `UIImagePickerControllerDelegate` and `UINavigationControllerDelegate`
        imagePicker.delegate = self

        // Present the image picker (camera)
        present(imagePicker, animated: true)
        
    }
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var captionField: UITextField!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func onPickedImageTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        
        //Set the filter to only show images as options
        config.filter = .images
        
        // Request the original file format
        config.preferredAssetRepresentationMode = .current
        
        //only allow 1 image to be selected at a time
        config.selectionLimit = 1
        
        //Instantiate a picker, passing in the configuration
        let picker = PHPickerViewController(configuration: config)
        
        //Set the picker delegate so we can receive whatever image the user picks
        picker.delegate = self
        present(picker, animated: true)
        
    }
    
    
    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
    @IBAction func onShareTapped(_ sender: Any) {
        view.endEditing(true)
        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else{
            return
        }
        
        let imageFile = ParseFile(name: "image.jpg", data: imageData)
        var post = Post()
        post.caption = captionField.text
        post.imageFile = imageFile
        post.user = User.current
        post.save{[weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("Post Saved! \(post)")
                    if var currentUser = User.current {

                        // Update the `lastPostedDate` property on the user with the current date.
                        currentUser.lastPostedDate = Date()

                        // Save updates to the user (async)
                        currentUser.save { [weak self] result in
                            switch result {
                            case .success(let user):
                                print("✅ User Saved! \(user)")

                                // Switch to the main thread for any UI updates
                                DispatchQueue.main.async {
                                    // Return to previous view controller
                                    self?.navigationController?.popViewController(animated: true)
                                }

                            case .failure(let error):
                                self?.showAlert(description: error.localizedDescription)
                            }
                        }
                    }
                    
//                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
}

extension PostFeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Dismiss the image picker
            picker.dismiss(animated: true)

            // Get the edited image from the info dictionary (if `allowsEditing = true` for image picker config).
            // Alternatively, to get the original image, use the `.originalImage` InfoKey instead.
            guard let image = info[.editedImage] as? UIImage else {
                print("❌📷 Unable to get image")
                return
            }

            // Set image on preview image view
            previewImageView.image = image

            // Set image to use when saving post
            pickedImage = image
    }

}
