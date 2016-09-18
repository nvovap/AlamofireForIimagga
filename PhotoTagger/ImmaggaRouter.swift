
import Foundation
import Alamofire

public enum ImaggaRouter: URLRequestConvertible {
  static let baseURLPath = "http://api.imagga.com/v1"
  static let authenticationToken = "Basic YWNjX2NiYzliMGEzMTdlNjI4Mjo2ODQwMDI3NzdiMTQ4MGNmNWMyNDAwZTgxNzM1YTYyMQ=="
  
  
  case Content
  case Tags(String)
  case Colors(String)
  
  public var URLRequest: NSMutableURLRequest {
    let result: (path: String, method: Alamofire.Method, parameters: [String: AnyObject]) = {
      switch self {
      case .Content:
        return ("/content", .POST, [String: AnyObject]())
      case .Tags(let contentID):
        let params = ["content": contentID]
        return ("\tagging", .GET, params)
      case .Colors(let contentID):
        let params = ["content": contentID, "extract_object_colors" : NSNumber(value: 0) ] as [String : Any]
        return ("\tagging", .GET, params)
      }
    }()
    
    
    let url = NSURL(string: ImaggaRouter.baseURLPath)!
    let URLRequest = NSMutableURLRequest(url: (url.appendingPathComponent(result.path))!)
//    URLRequest.httpMethod = result.method
    URLRequest.setValue(ImaggaRouter.authenticationToken, forHTTPHeaderField: "Authorization")
    URLRequest.timeoutInterval = TimeInterval(10 * 100)
    
    let encoding = Alamofire.ParameterEncoding.url
    
    return encoding.encode(URLRequest, parameters: result.parameters).0
    
  }
  


}
