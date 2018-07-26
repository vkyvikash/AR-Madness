//
//  ViewController.swift
//  ARMadness
//
//  Created by Vikash Kumar on 14/07/18.
//  Copyright © 2018 Vikash Kumar. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate{

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var timerLabel : UILabel!
    @IBOutlet weak var scoreLabel : UILabel!
    
    var score = 0
    
    // Buttons
    @IBAction func onAxeButton(_ sender: Any) {
        fireMissile(type: "axe")
    }
    
    @IBAction func onBananaButton(_ sender: Any) {
        fireMissile(type: "banana")
    }
    
    //MARK: - maths
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            // 4x4  transform matrix describing camera in world space
            let mat = SCNMatrix4(frame.camera.transform)
            // orientation of camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            // location of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        //set the physics delegate
        sceneView.scene.physicsWorld.contactDelegate = self
        
        addTargetNodes()
        
        // Play background music
        playBackgroundMusic()
        
        runTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        if seconds == 0 {
            timer.invalidate()
            gameOver()
        }else{
            seconds -= 1
            timerLabel.text = "\(seconds)"
        }
    }
    
    func resetTimer(){
        timer.invalidate()
        seconds = 60
        timerLabel.text = "\(seconds)"
    }
    
    func gameOver(){
        //store the score in UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(score, forKey: "score")
        //go back to the Home View Controller
        self.dismiss(animated: true, completion: nil)
    }
    
    func fireMissile(type : String){
        var node = SCNNode()
        node = createMissile(type: type)
        let (direction, position) = self.getUserVector()
        node.position = position
        var nodeDirection = SCNVector3()
        switch type {
        case "banana":
            nodeDirection  = SCNVector3(direction.x*5,direction.y*5,direction.z*5)
            node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1,0,0), asImpulse: true)
            playSound(sound: "monkey", format: "mp3")
        case "axe":
            nodeDirection  = SCNVector3(direction.x*5,direction.y*5,direction.z*5)
            node.physicsBody?.applyForce(SCNVector3(direction.x,direction.y,direction.z), at: SCNVector3(0,0,0.1), asImpulse: true)
            playSound(sound: "rooster", format: "mp3")
        default:
            nodeDirection = direction
        }
        
        node.physicsBody?.applyForce(nodeDirection , asImpulse: true)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    // MARK : - creating missiles
    
    func createMissile(type : String)->SCNNode{
        var node = SCNNode()
        
        //using case statement to allow variations of scale and rotations
        switch type {
        case "banana":
            let scene = SCNScene(named: "art.scnassets/banana.dae")
            node = (scene?.rootNode.childNode(withName: "Cube_001", recursively: true)!)!
            node.scale = SCNVector3(0.02,0.02,0.02)
            node.name = "banana"
        case "axe":
            let scene = SCNScene(named: "art.scnassets/axe.dae")
            node = (scene?.rootNode.childNode(withName: "axe", recursively: true)!)!
            node.scale = SCNVector3(0.02,0.02,0.02)
            node.name = "bathtub"
        default:
            node = SCNNode()
        }
        
        //the physics body governs how the object interacts with other objects and its environment
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        
        //these bitmasks used to define "collisions" with other objects
        node.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        return node
    }
    
    func addTargetNodes() {
        for index in 1...50 {
            var node = SCNNode()
            
            if (index > 4) && (index%5 == 0) {
                // For every 10th index, a shark
                let scene = SCNScene(named: "art.scnassets/mouthshark.dae")
                node = (scene?.rootNode.childNode(withName: "shark", recursively: true)!)!
                node.scale = SCNVector3(0.3, 0.3, 0.3)
                node.name = "shark"
            } else {
                // everything else will be a bathtub
                let scene = SCNScene(named: "art.scnassets/bath.dae")
                node = (scene?.rootNode.childNode(withName: "Cube_001", recursively: true)!)!
                node.scale = SCNVector3(0.05, 0.05, 0.05)
                node.name = "bath"
            }
            
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            node.physicsBody?.isAffectedByGravity = false
            
            // Place randomly within threshold
            node.position = SCNVector3(randomFloat(min: -10, max: 10),randomFloat(min: -4, max: 5),randomFloat(min: -10, max: 10))
            
            // rotate
            let action : SCNAction = SCNAction.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 1.0)
            let forever = SCNAction.repeatForever(action)
            node.runAction(forever)
            
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
            // Add to scene
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - Contact Delegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        print("** Collision!! " + contact.nodeA.name! + " hit " + contact.nodeB.name!)
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            if (contact.nodeA.name! == "shark" || contact.nodeB.name! == "shark") {
                score+=5
            }else{
                score+=1
            }
            
            DispatchQueue.main.async {
                contact.nodeA.removeFromParentNode()
                contact.nodeB.removeFromParentNode()
                self.scoreLabel.text = String(self.score)
            }
            
            playSound(sound: "explosion", format: "wav")
            
            let  explosion = SCNParticleSystem(named: "Explode", inDirectory: nil)
            contact.nodeB.addParticleSystem(explosion!)
        }
    }
    
    var player: AVAudioPlayer?
    
    func playSound(sound : String, format: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: format) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playBackgroundMusic() {
        let audioNode = SCNNode()
        let audioSource = SCNAudioSource(fileNamed: "overtake.mp3")!
        let audioPlayer = SCNAudioPlayer(source: audioSource)
        
        audioNode.addAudioPlayer(audioPlayer)
        
        let play = SCNAction.playAudio(audioSource, waitForCompletion: true)
        audioNode.runAction(play)
        sceneView.scene.rootNode.addChildNode(audioNode)
    }
}

struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let missileCategory  = CollisionCategory(rawValue: 1 << 0) // for bananas and axes
    static let targetCategory = CollisionCategory(rawValue: 1 << 1) // for bathtubs and sharks
}
