import Foundation
import VisionKit
import React

/**
 The core native implementation of the Document Scanner.

 This class handles:
 1. Interfacing with `VNDocumentCameraViewController`.
 2. Managing the scanning session lifecycle.
 3. Delegating processing to `ImageProcessor`.
 */
@objc(DocumentScannerManager)
@available(iOS 13.0, *)
public class DocumentScannerManager: NSObject, VNDocumentCameraViewControllerDelegate {

  private var resolve: RCTPromiseResolveBlock?
  private var reject: RCTPromiseRejectBlock?
  private var scanOptions: [String: Any]?

  /* ----------------------------------------------------------------------- */
  /* Scan Operations                                                         */
  /* ----------------------------------------------------------------------- */

  @objc
  public func scanDocuments(_ options: NSDictionary?, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.resolve = resolve
    self.reject = reject
    self.scanOptions = options as? [String: Any]

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      guard VNDocumentCameraViewController.isSupported else {
        self.rejectError(.notSupported)
        return
      }

      let scannerViewController = VNDocumentCameraViewController()
      scannerViewController.delegate = self
      scannerViewController.modalPresentationStyle = .fullScreen

      if let topController = self.getTopMostViewController() {
        topController.present(scannerViewController, animated: true, completion: nil)
      } else {
        self.rejectError(.operationFailed("Could not find top view controller."))
      }
    }
  }

  /* ----------------------------------------------------------------------- */
  /* Process Operations                                                      */
  /* ----------------------------------------------------------------------- */
  @objc
  public func processDocuments(_ options: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.resolve = resolve
    self.reject = reject

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      guard let opts = ProcessOptions(from: options as? [String: Any]) else {
        self.rejectError(.configurationError("Missing 'images' array in options"))
        return
      }

      /* Load images from sources */
      let images = opts.images.compactMap { ImageUtil.loadImage(from: $0) }

      if images.isEmpty {
        self.rejectError(.configurationError("Could not load any valid images"))
        return
      }

      /* Process all images */
      let results = ImageProcessor.processAll(images, options: opts)

      self.resolve?(results.map { $0.dictionary })
      self.cleanup()
    }
  }

  /* ----------------------------------------------------------------------- */
  /* VNDocumentCameraViewControllerDelegate                                  */
  /* ----------------------------------------------------------------------- */

  public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    controller.dismiss(animated: true) { [weak self] in
      self?.processScan(scan)
    }
  }

  public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true) { [weak self] in
      self?.rejectError(.canceled)
    }
  }

  public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true) { [weak self] in
      self?.rejectError(.operationFailed(error.localizedDescription))
    }
  }

  /* ----------------------------------------------------------------------- */
  /* Private Helpers                                                         */
  /* ----------------------------------------------------------------------- */

  private func processScan(_ scan: VNDocumentCameraScan) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      let opts = ScanOptions(from: self.scanOptions, fallbackPageCount: scan.pageCount)
      let pageLimit = min(scan.pageCount, opts.maxPageCount)

      /* Collect images from scan */
      var images: [UIImage] = []
      for i in 0..<pageLimit {
        images.append(scan.imageOfPage(at: i))
      }

      /* Process all images */
      let results = ImageProcessor.processAll(images, options: opts)

      self.resolve?(results.map { $0.dictionary })
      self.cleanup()
    }
  }

  private func getTopMostViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
        return UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
    } else {
        return UIApplication.shared.keyWindow?.rootViewController
    }
  }

  private func rejectError(_ error: ScannerError) {
      self.reject?("error", error.localizedDescription, error)
      self.cleanup()
  }

  private func cleanup() {
    self.resolve = nil
    self.reject = nil
    self.scanOptions = nil
  }
}
