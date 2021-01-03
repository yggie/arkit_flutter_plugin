import Foundation
import ARKit

class FlutterArkitView: NSObject, FlutterPlatformView {
    let sceneView: ARSCNView
    let channel: FlutterMethodChannel
    var result: FlutterResult!
    var imagePath: String!
    
    var forceTapOnCenter: Bool = false
    var configuration: ARConfiguration? = nil
    
    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger msg: FlutterBinaryMessenger) {
        self.sceneView = ARSCNView(frame: frame)
        self.channel = FlutterMethodChannel(name: "arkit_\(viewId)", binaryMessenger: msg)
        
        super.init()
        
        self.sceneView.delegate = self
        self.channel.setMethodCallHandler(self.onMethodCalled)
    }
    
    func view() -> UIView { return sceneView }
    
    func onMethodCalled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
        
        if configuration == nil && call.method != "init" {
            logPluginError("plugin is not initialized properly", toChannel: channel)
            result(nil)
            return
        }
        
        switch call.method {
        case "init":
            initalize(arguments!, result)
            result(nil)
            break
        case "addARKitNode":
            onAddNode(arguments!)
            result(nil)
            break
        case "onUpdateNode":
            onUpdateNode(arguments!)
            result(nil)
            break
        case "removeARKitNode":
            onRemoveNode(arguments!)
            result(nil)
            break
        case "removeARKitAnchor":
            onRemoveAnchor(arguments!)
            result(nil)
            break
        case "getNodeBoundingBox":
            onGetNodeBoundingBox(arguments!, result)
            break
        case "transformationChanged":
            onTransformChanged(arguments!)
            result(nil)
            break
        case "isHiddenChanged":
            onIsHiddenChanged(arguments!)
            result(nil)
            break
        case "updateSingleProperty":
            onUpdateSingleProperty(arguments!)
            result(nil)
            break
        case "updateMaterials":
            onUpdateMaterials(arguments!)
            result(nil)
            break
        case "performHitTest":
            onPerformHitTest(arguments!, result)
            break
        case "updateFaceGeometry":
            onUpdateFaceGeometry(arguments!)
            result(nil)
            break
        case "getLightEstimate":
            onGetLightEstimate(result)
            result(nil)
            break
        case "projectPoint":
            onProjectPoint(arguments!, result)
            break
        case "cameraProjectionMatrix":
            onCameraProjectionMatrix(result)
            break
        case "pointOfViewTransform":
            onPointOfViewTransform(result)
            break
        case "playAnimation":
            onPlayAnimation(arguments!)
            result(nil)
            break
        case "stopAnimation":
            onStopAnimation(arguments!)
            result(nil)
            break
        case "dispose":
            onDispose(result)
            result(nil)
            break
        case "cameraEulerAngles":
            onCameraEulerAngles(result)
            break

        case "snapshot":
            onGetSnapshot(result)
            break

        case "captureImage":
            UIGraphicsBeginImageContextWithOptions(self.sceneView.bounds.size, false, UIScreen.main.scale)

            self.sceneView.drawHierarchy(in: self.sceneView.bounds, afterScreenUpdates: true)

            let optionalImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            guard let image = optionalImage else {
                result("No image produced from context")
                return
            }

            guard let imageData = image.pngData() else {
                result("Cannot retrieve image PNG")
                return
            }

            let paths: [URL] = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

            guard let dir = paths.first else {
                result("No paths for app")
                return
            }

            guard let filename = arguments!["filename"] as! String? else {
                result("filename is required")
                return
            }

            let path = dir.appendingPathComponent(filename)
            guard let _ = try? imageData.write(to: path) else {
                result("Image cannot be written")
                return
            }

            self.result = result
            self.imagePath = path.path
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(savedToGalleryDone), nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    @objc
    func savedToGalleryDone(image: UIImage, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        if error == nil && self.imagePath != nil && !self.imagePath.isEmpty {
            self.result(self.imagePath)
        } else {
            self.result("There was an issue")
        }
    } // savedToGalleryDone()
    
    func onDispose(_ result:FlutterResult) {
        sceneView.session.pause()
        self.channel.setMethodCallHandler(nil)
        result(nil)
    }
}
