import UserNotifications
import UploadAttachments

class NotificationService: UNNotificationServiceExtension {
  
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?
  
  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    if let bestAttemptContent = bestAttemptContent {
      let ackId = bestAttemptContent.userInfo["ack_id"]
      let type = bestAttemptContent.userInfo["type"]
      let postId = bestAttemptContent.userInfo["post_id"]
      UploadSession.shared.notificationReceipt(
        notificationId: ackId,
        receivedAt: Date().millisencondsSince1970,
        type: type,
        postId: postId
      ) { data, error in
        if (type as? String == "id_loaded") {
          guard let data = data, error == nil else {
            // TODO: set default notification message
            return
          }

          do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            print(json)
          } catch {
            print("JSON error: \(error.localizedDescription)")
          }
        }
      }
      
      contentHandler(bestAttemptContent)
    }
  }
  
  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
  
}

extension Date {
  var millisencondsSince1970: Int {
    return Int((self.timeIntervalSince1970 * 1000.0).rounded())
  }
  
  init(milliseconds: Int) {
    self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
  }
}
