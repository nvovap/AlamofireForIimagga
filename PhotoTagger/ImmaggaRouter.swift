
import Foundation
import Alamofire

public enum ImaggaRouter: URLRequestConvertible {

  

  static let baseURLPath = "http://api.imagga.com/v1"
  static let authenticationToken = "Basic YWNjX2NiYzliMGEzMTdlNjI4Mjo2ODQwMDI3NzdiMTQ4MGNmNWMyNDAwZTgxNzM1YTYyMQ=="
  
  case Content
  case Tags(String)
  case Colors(String)
  
  
  var urlRequest: URLRequest {
    let result: (path: String, method: Alamofire.HTTPMethod, parameters: [String: AnyObject]) = {
      switch self {
      case .Content:
        return ("/content", .post, [String: AnyObject]())
      case .Tags(let contentID):
        let params = ["content": contentID]
        return ("\tagging", .get, params as [String : AnyObject])
      case .Colors(let contentID):
        let params = ["content": contentID, "extract_object_colors" : NSNumber(value: 0) ] as [String : Any]
        return ("\tagging", .get, params as [String : AnyObject])
      }
    }()
  
    
    
    let url = NSURL(string: ImaggaRouter.baseURLPath)!
    let tempURLRequest = NSMutableURLRequest(url: (url.appendingPathComponent(result.path))!)
    tempURLRequest.httpMethod = result.method.rawValue
    tempURLRequest.setValue(ImaggaRouter.authenticationToken, forHTTPHeaderField: "Authorization")
    tempURLRequest.timeoutInterval = TimeInterval(10 * 100)
    
    let urlResult = try! Alamofire.URLEncoding().encode(tempURLRequest as! URLRequestConvertible, with: result.parameters)
    
    
    return urlResult
    
  }
  
    
  
  public func asURLRequest() throws -> URLRequest {
    return urlRequest
  }



}
