//
//  GameScene.swift
//  Flappy Swift
//
//  Created by Julio Montoya on 05/01/16.
//  Copyright (c) 2016 Julio Montoya. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import SpriteKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// Math helpers
extension Float {
  static func clamp(_ min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
    if (value > max) {
      return max
    } else if (value < min) {
      return min
    } else {
      return value
    }
  }
  
  static func range(_ min: CGFloat, max: CGFloat) -> CGFloat {
    return CGFloat.random(in: min...max)
  }
}

extension CGFloat {
  func degrees_to_radians() -> CGFloat {
    return CGFloat(Double.pi) * self / 180.0
  }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
  // Bird
  var bird: SKSpriteNode!
  
  // Background
  var background: SKNode!
  let background_speed = 100.0
  
  // Score
  var score = 0
  var label_score: SKLabelNode!
  
  // Instructions
  var instructions: SKSpriteNode!
  
  // Pipe Origin
  let pipe_origin_x: CGFloat = 382.0
  
  // Floor height
  let floor_distance: CGFloat = 72.0
  
  // Time Values
  var delta = TimeInterval(0)
  var last_update_time = TimeInterval(0)
  
  // Physics Categories
  let FSBoundaryCategory: UInt32 = 1 << 0
  let FSPlayerCategory: UInt32   = 1 << 1
  let FSPipeCategory: UInt32     = 1 << 2
  let FSGapCategory: UInt32      = 1 << 3
  
  // Game States
  enum FSGameState: Int {
    case fsGameStateStarting
    case fsGameStatePlaying
    case fsGameStateEnded
  }
  
  var state = FSGameState.fsGameStateStarting
  
  // MARK: - SKScene Initializacion
  override func didMove(to view: SKView) {
    initWorld()
    initBackground()
    initBird()
    initHUD()
  }
  
  // MARK: - Init Physics
  func initWorld() {
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
    physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0.0, y: floor_distance, width: size.width, height: size.height - floor_distance))
    physicsBody?.categoryBitMask = FSBoundaryCategory
    physicsBody?.collisionBitMask = FSPlayerCategory
  }
  
  // MARK: - Init Bird
  func initBird() {
    bird = SKSpriteNode(imageNamed: "bird1")
    bird.position = CGPoint(x: 100.0, y: frame.midY)
    bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.width / 2.5)
    bird.physicsBody?.categoryBitMask = FSPlayerCategory
    bird.physicsBody?.contactTestBitMask = FSPipeCategory | FSGapCategory | FSBoundaryCategory
    bird.physicsBody?.collisionBitMask = FSPipeCategory | FSBoundaryCategory
    bird.physicsBody?.affectedByGravity = false
    bird.physicsBody?.allowsRotation = false
    bird.physicsBody?.restitution = 0.0
    bird.zPosition = 50
    addChild(bird)
    
    let texture1 = SKTexture(imageNamed: "bird1")
    let texture2 = SKTexture(imageNamed: "bird2")
    let textures = [texture1, texture2]
    
    bird.run(SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: 0.1)))
  }
  
  // MARK: - Score
  func initHUD() {
    label_score = SKLabelNode(fontNamed:"MarkerFelt-Wide")
    label_score.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
    label_score.text = "0"
    label_score.zPosition = 50
    self.addChild(label_score)
    
    instructions = SKSpriteNode(imageNamed: "TapToStart")
    instructions.position = CGPoint(x: frame.midX, y: frame.midY - 10)
    instructions.zPosition = 50
    addChild(instructions)
  }
  
  // MARK: - Background Functions
  func initBackground() {
    background = SKNode()
    addChild(background)
    
    for i in 0...2 {
      let tile = SKSpriteNode(imageNamed: "bg")
      tile.anchorPoint = CGPoint.zero
      tile.position = CGPoint(x: CGFloat(i) * 640.0, y: 0.0)
      tile.name = "bg"
      tile.zPosition = 10
      background.addChild(tile)
    }
  }
  
  func moveBackground() {
    let posX = -background_speed * delta
    background.position = CGPoint(x: background.position.x + CGFloat(posX), y: 0.0)
    background.enumerateChildNodes(withName: "bg") { (node, stop) in
      let background_screen_position = self.background.convert(node.position, to: self)
      if background_screen_position.x <= -node.frame.size.width {
        node.position = CGPoint(x: node.position.x + (node.frame.size.width * 2), y: node.position.y)
      }
    }
  }
  
  // MARK: - Pipes Functions
  func initPipes() {
    let screenSize = UIScreen.main.bounds
    let isWideScreen = (screenSize.height > 480)
    
    let bottom = getPipeWithSize(CGSize(width: 62, height: Float.range(40, max: isWideScreen ? 360 : 280)), side: false)
    bottom.position = convert(CGPoint(x: pipe_origin_x, y: frame.minY + bottom.size.height/2 + floor_distance), to: background)
    bottom.physicsBody = SKPhysicsBody(rectangleOf: bottom.size)
    bottom.physicsBody?.categoryBitMask = FSPipeCategory;
    bottom.physicsBody?.contactTestBitMask = FSPlayerCategory;
    bottom.physicsBody?.collisionBitMask = FSPlayerCategory;
    bottom.physicsBody?.isDynamic = false
    bottom.zPosition = 20
    background.addChild(bottom)
    
    let threshold = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 10, height: 100))
    threshold.position = convert(CGPoint(x: pipe_origin_x, y: floor_distance + bottom.size.height + threshold.size.height/2), to: background)
    threshold.physicsBody = SKPhysicsBody(rectangleOf: threshold.size)
    threshold.physicsBody?.categoryBitMask = FSGapCategory
    threshold.physicsBody?.contactTestBitMask = FSPlayerCategory
    threshold.physicsBody?.collisionBitMask = 0
    threshold.physicsBody?.isDynamic = false
    threshold.zPosition = 20
    background.addChild(threshold)
    
    let topSize = size.height - bottom.size.height - threshold.size.height - floor_distance
    let top = getPipeWithSize(CGSize(width: 62, height: topSize), side: true)
    top.position = convert(CGPoint(x: pipe_origin_x, y: frame.maxY - top.size.height/2), to: background)
    top.physicsBody = SKPhysicsBody(rectangleOf: top.size)
    top.physicsBody?.categoryBitMask = FSPipeCategory;
    top.physicsBody?.contactTestBitMask = FSPlayerCategory;
    top.physicsBody?.collisionBitMask = FSPlayerCategory;
    top.physicsBody?.isDynamic = false
    top.zPosition = 20
    background.addChild(top)
  }
  
  func getPipeWithSize(_ size: CGSize, side: Bool) -> SKSpriteNode {
    let textureSize = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
    let backgroundCGImage = UIImage(named: "pipe")!.cgImage
    
    UIGraphicsBeginImageContext(size)
    let context = UIGraphicsGetCurrentContext()
    context?.draw(backgroundCGImage!, in: CGRect(x: 0.0, y: 0.0, width: textureSize.width, height: textureSize.height))
    let tiledBackground = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    let backgroundTexture = SKTexture(cgImage: tiledBackground!.cgImage!)
    let pipe = SKSpriteNode(texture: backgroundTexture)
    pipe.zPosition = 1
    
    let cap = SKSpriteNode(imageNamed: "bottom")
    cap.position = CGPoint(x: 0.0, y: side ? -pipe.size.height/2 + cap.size.height/2 : pipe.size.height/2 - cap.size.height/2)
    cap.zPosition = 5
    pipe.addChild(cap)
    
    if side {
      let angle:CGFloat = 180.0
      cap.zRotation = angle.degrees_to_radians()
    }
    
    return pipe
  }
  
  // MARK: - Game Over helpers
  func gameOver() {
    state = .fsGameStateEnded
    bird.physicsBody?.categoryBitMask = 0
    bird.physicsBody?.collisionBitMask = FSBoundaryCategory
    
    removeAction(forKey: "generator")
    
    _ = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.restartGame), userInfo: nil, repeats: false)
  }
  
  @objc func restartGame() {
    state = .fsGameStateStarting
    bird.removeFromParent()
    background.removeAllChildren()
    background.removeFromParent()
    
    instructions.isHidden = false
    
    score = 0
    label_score.text = "0"
    
    initBird()
    initBackground()
  }
  
  // MARK: - SKPhysicsContactDelegate
  func didBegin(_ contact: SKPhysicsContact) {
    let collision:UInt32 = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask)
    
    if collision == (FSPlayerCategory | FSGapCategory) {
      score += 1
      label_score.text = "\(score)"
    }
    
    if collision == (FSPlayerCategory | FSPipeCategory) {
      gameOver()
    }
    
    if collision == (FSPlayerCategory | FSBoundaryCategory) {
      if bird.position.y < 150 {
        gameOver()
      }
    }
  }
  
  // MARK: - Touch Events
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if state == .fsGameStateStarting {
      state = .fsGameStatePlaying
      
      instructions.isHidden = true
      bird.physicsBody?.affectedByGravity = true
      bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
      
      run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.run {
        self.initPipes()
      }])), withKey: "generator")
    } else if state == .fsGameStatePlaying {
      bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    }
  }
  
  // MARK: - Frames Per Second
  override func update(_ currentTime: TimeInterval) {
    delta = (last_update_time == 0.0) ? 0.0 : currentTime - last_update_time
    last_update_time = currentTime
    
    if state != .fsGameStateEnded {
      moveBackground()
      
      let velocity_x = bird.physicsBody?.velocity.dx
      let velocity_y = bird.physicsBody?.velocity.dy
      
      if bird.physicsBody?.velocity.dy > 280 {
        bird.physicsBody?.velocity = CGVector(dx: velocity_x!, dy: 280)
      }
      
      bird.zRotation = Float.clamp(-1, max: 0.0, value: velocity_y! * (velocity_y < 0 ? 0.003 : 0.001))
    } else {
      bird.zRotation = CGFloat(Double.pi)
      bird.removeAllActions()
    }
  }
}
