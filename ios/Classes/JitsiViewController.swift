@IBOutlet weak var videoButton: UIButton?

//CHEAT
fileprivate var pipViewCoordinator: PiPViewCoordinator?
fileprivate var jitsiMeetView: JitsiMeetView?

var eventSink:FlutterEventSink? = nil
var roomName:String? = nil
var serverUrl:URL? = nil
var subject:String? = nil
var audioOnly:Bool? = false
var audioMuted: Bool? = false
var videoMuted: Bool? = false
var token:String? = nil
var featureFlags: Dictionary<String, Any>? = Dictionary();
var zoomButton: UIButton?


var jistiMeetUserInfo = JitsiMeetUserInfo()

override func loadView() {
    
    super.loadView()
}

@objc func openButtonClicked(sender : UIButton){
    
    //openJitsiMeetWithOptions();
}

@objc func closeButtonClicked(sender : UIButton){
    cleanUp();
    self.dismiss(animated: true, completion: nil)
}

override func viewDidLoad() {
    
    //print("VIEW DID LOAD")
    self.view.backgroundColor = .black
    
    super.viewDidLoad()
}

override func viewDidAppear(_ animated: Bool) {
    openJitsiMeet();
}

override func viewWillTransition(to size: CGSize,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    let rect = CGRect(origin: CGPoint.zero, size: size)
    pipViewCoordinator?.resetBounds(bounds: rect)
    
    
}

func openJitsiMeet() {
    cleanUp()
    // create and configure jitsimeet view
    let jitsiMeetView = JitsiMeetView()
    
    
    jitsiMeetView.delegate = self
    self.jitsiMeetView = jitsiMeetView
    let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
        builder.welcomePageEnabled = true
        builder.room = self.roomName
        builder.serverURL = self.serverUrl
        builder.subject = self.subject
        builder.userInfo = self.jistiMeetUserInfo
        builder.audioOnly = self.audioOnly ?? false
        builder.audioMuted = self.audioMuted ?? false
        builder.videoMuted = self.videoMuted ?? false
        builder.token = self.token
        
        self.featureFlags?.forEach{ key,value in
            builder.setFeatureFlag(key, withValue: value);
        }
        
    }
    
    jitsiMeetView.join(options)
    
    // Enable jitsimeet view to be a view that can be displayed
    // on top of all the things, and let the coordinator to manage
    // the view state and interactions
    
    //Original
// pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
// pipViewCoordinator?.configureAsStickyView(withParentView: view)

    //New code by Amol
    pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
    pipViewCoordinator?.configureAsStickyView(withParentView: view.window)
    
    // animate in
    //jitsiMeetView.alpha = 0
    pipViewCoordinator?.show()
//as soon as start meet open in pip mode
enterPicture(inPicture: [:])
}

func closeJitsiMeeting(){
    jitsiMeetView?.leave()
}

fileprivate func cleanUp() {
    jitsiMeetView?.removeFromSuperview()
    jitsiMeetView = nil
    pipViewCoordinator = nil
    //self.dismiss(animated: true, completion: nil)
}
}

extension JitsiViewController: JitsiMeetViewDelegate {

func conferenceWillJoin(_ data: [AnyHashable : Any]!) {
    //        print("CONFERENCE WILL JOIN")
    var mutatedData = data
    mutatedData?.updateValue("onConferenceWillJoin", forKey: "event")
    self.eventSink?(mutatedData)
}

func conferenceJoined(_ data: [AnyHashable : Any]!) {
    //        print("CONFERENCE JOINED")
    var mutatedData = data
    mutatedData?.updateValue("onConferenceJoined", forKey: "event")
    self.eventSink?(mutatedData)
}

func conferenceTerminated(_ data: [AnyHashable : Any]!) {
    //        print("CONFERENCE TERMINATED")
    var mutatedData = data
    mutatedData?.updateValue("onConferenceTerminated", forKey: "event")
    self.eventSink?(mutatedData)
    
    DispatchQueue.main.async {
        self.pipViewCoordinator?.hide() { _ in
            self.cleanUp()
            self.dismiss(animated: true, completion: nil)
            self.view.removeFromSuperview()
        }
    }
    
}

func enterPicture(inPicture data: [AnyHashable : Any]!) {
    self.view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

    var mutatedData = data
    mutatedData?.updateValue("onPictureInPictureWillEnter", forKey: "event")
    self.eventSink?(mutatedData)
    DispatchQueue.main.async {
        self.pipViewCoordinator?.enterPictureInPicture()
    }
    
            print("CONFERENCE PIP IN \(mutatedData)")

}

func exitPictureInPicture() {
    var mutatedData : [AnyHashable : Any]
    mutatedData = ["event":"onPictureInPictureTerminated"]
    self.eventSink?(mutatedData)
            print("CONFERENCE PIP OUT \(mutatedData)")

}
}

