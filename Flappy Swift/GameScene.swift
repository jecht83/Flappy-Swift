//
//  GameScene.swift
//  Flappy Swift
//
//  Created by Julio Montoya on 13/07/14.
//  Copyright (c) 2014 Julio Montoya. All rights reserved.
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

// #pragma mark - Math functions
extension Float {
  static func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
    if(value > max) {
      return max
    } else if(value < min) {
      return min
    } else {
      return value
    }
  }
    
  static func range(min: CGFloat, max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
  }
}

extension CGFloat {
  func degrees_to_radians() -> CGFloat {
    return CGFloat(M_PI) * self / 180.0
  }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
  // Bird
  var bird = SKSpriteNode(imageNamed: "bird1")
    
  // Background
  let background:SKNode = SKNode()
  let background_speed = 100.0
    
  // Score
  var score = 0
  var label_score = SKLabelNode(fontNamed:"MarkerFelt-Wide")
    
  // Instructions
  var instructions = SKSpriteNode(imageNamed: "TapToStart")
    
  // Pipe Origin
  let pipe_origin_x:CGFloat = 382.0
    
  // Floor height
  let floor_distance:CGFloat = 72.0
    
  // Time Values
  var delta = NSTimeInterval(0)
  var last_update_time = NSTimeInterval(0)
    
  // Physics Categories
  let FSBoundaryCategory:UInt32 = 1 << 0
  let FSPlayerCategory:UInt32   = 1 << 1
  let FSPipeCategory:UInt32     = 1 << 2
  let FSGapCategory:UInt32      = 1 << 3
    
  // Game States
    
  enum FSGameState: Int {
    case FSGameStateStarting
    case FSGameStatePlaying
    case FSGameStateEnded
  }
    
  var state = FSGameState.FSGameStateStarting
    
  // #pragma mark - SKScene Initializacion
    
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
    
  override init(size: CGSize) {
    super.init(size: size)
        
    initWorld()
    initBackground()
    initBird()
    initHUD()
  }
    
  // #pragma mark - Init Physics
  func initWorld() {
    self.physicsWorld.contactDelegate = self
    self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
    self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: 0.0, y: floor_distance, width: self.size.width, height: self.size.height - floor_distance))
    self.physicsBody?.categoryBitMask = FSBoundaryCategory
    self.physicsBody?.collisionBitMask = FSPlayerCategory
  }
    
  // #pragma mark - Init Bird
  func initBird() {
    bird.position = CGPoint(x: 100.0, y: CGRectGetMidY(self.frame))
    bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.width / 2.5)
    bird.physicsBody?.categoryBitMask = FSPlayerCategory
    bird.physicsBody?.contactTestBitMask = FSPipeCategory | FSGapCategory | FSBoundaryCategory
    bird.physicsBody?.collisionBitMask = FSPipeCategory | FSBoundaryCategory
    bird.physicsBody?.affectedByGravity = false
    bird.physicsBody?.allowsRotation = false
    bird.physicsBody?.restitution = 0.0
    bird.zPosition = 50
    self.addChild(bird)
        
    let texture1: SKTexture = SKTexture(imageNamed: "bird1")
    let texture2: SKTexture = SKTexture(imageNamed: "bird2")
    let textures = [texture1, texture2]
        
    bird.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.1)))
  }
    
  // #pragma mark Score
    
  func initHUD() {
    label_score.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMaxY(self.frame) - 100)
    label_score.text = "0"
    label_score.zPosition = 50
    self.addChild(label_score)
        
    instructions.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame) - 10)
    instructions.zPosition = 50
    self.addChild(instructions)
  }
    
  // #pragma mark - Background Functions
  func initBackground() {
    self.addChild(background)
    
    for i in 0...2 {
      let tile = SKSpriteNode(imageNamed: "bg")
      tile.anchorPoint = CGPointZero
      tile.position = CGPoint(x: CGFloat(i) * 640.0, y: 0.0)
      tile.name = "bg"
      tile.zPosition = 10
      background.addChild(tile)
    }
  }
    
  func moveBackground() {
    let posX = -background_speed * delta
    background.position = CGPoint(x: background.position.x + CGFloat(posX), y: 0.0)
    background.enumerateChildNodesWithName("bg") { (node, stop) in
      let background_screen_position = self.background.convertPoint(node.position, toNode: self)
      if background_screen_position.x <= -node.frame.size.width {
        node.position = CGPoint(x: node.position.x + (node.frame.size.width * 2), y: node.position.y)
      }
    }
  }
    
  // #pragma mark - Pipes Functions
  func initPipes() {
    let screenSize = UIScreen.mainScreen().bounds
    let isWideScreen = (screenSize.height > 480)
    let bottom = self.getPipeWithSize(CGSizeMake(62, Float.range(40, max: isWideScreen ? 360 : 280)), side: false)
    bottom.position = self.convertPoint(CGPointMake(pipe_origin_x, CGRectGetMinY(self.frame) + bottom.size.height/2 + floor_distance), toNode: background)
    bottom.physicsBody = SKPhysicsBody(rectangleOfSize: bottom.size)
    bottom.physicsBody?.categoryBitMask = FSPipeCategory;
    bottom.physicsBody?.contactTestBitMask = FSPlayerCategory;
    bottom.physicsBody?.collisionBitMask = FSPlayerCategory;
    bottom.physicsBody?.dynamic = false
    bottom.zPosition = 20
    background.addChild(bottom)
        
    let threshold = SKSpriteNode(color: UIColor.clearColor(), size: CGSizeMake(10, 100))
    threshold.position = self.convertPoint(CGPoint(x: pipe_origin_x, y: floor_distance + bottom.size.height + threshold.size.height/2), toNode: background)
    threshold.physicsBody = SKPhysicsBody(rectangleOfSize: threshold.size)
    threshold.physicsBody?.categoryBitMask = FSGapCategory
    threshold.physicsBody?.contactTestBitMask = FSPlayerCategory
    threshold.physicsBody?.collisionBitMask = 0
    threshold.physicsBody?.dynamic = false
    threshold.zPosition = 20
    background.addChild(threshold)
        
    let topSize = self.size.height - bottom.size.height - threshold.size.height - floor_distance
    let top = self.getPipeWithSize(CGSizeMake(62, topSize), side: true)
    top.position = self.convertPoint(CGPoint(x: pipe_origin_x, y: CGRectGetMaxY(self.frame) - top.size.height/2), toNode: background)
    top.physicsBody = SKPhysicsBody(rectangleOfSize: top.size)
    top.physicsBody?.categoryBitMask = FSPipeCategory;
    top.physicsBody?.contactTestBitMask = FSPlayerCategory;
    top.physicsBody?.collisionBitMask = FSPlayerCategory;
    top.physicsBody?.dynamic = false
    top.zPosition = 20
    background.addChild(top)
  }
    
  func getPipeWithSize(size: CGSize, side: Bool) -> SKSpriteNode {
    let textureSize = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
    let backgroundCGImage = UIImage(named: "pipe")!.CGImage

    UIGraphicsBeginImageContext(size)
    let context = UIGraphicsGetCurrentContext()
    CGContextDrawTiledImage(context, textureSize, backgroundCGImage)
    let tiledBackground = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
        
    let backgroundTexture = SKTexture(CGImage: tiledBackground.CGImage)
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
    
  // #pragma mark - Game Over helpers
  func gameOver() {
    state = .FSGameStateEnded
    bird.physicsBody?.categoryBitMask = 0
    bird.physicsBody?.collisionBitMask = FSBoundaryCategory
        
    var timer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: Selector("restartGame"), userInfo: nil, repeats: false)
  }
    
  func restartGame() {
    state = .FSGameStateStarting
    bird.removeFromParent()
    background.removeAllChildren()
    background.removeFromParent()
        
    instructions.hidden = false
    self.removeActionForKey("generator")

    score = 0
    label_score.text = "0"

    initBird()
    initBackground()
  }
    
  // #pragma mark - SKPhysicsContactDelegate
  func didBeginContact(contact: SKPhysicsContact!) {
    let collision:UInt32 = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask)
        
    if collision == (FSPlayerCategory | FSGapCategory) {
      score++
      label_score.text = "\(score)"
    }
        
    if collision == (FSPlayerCategory | FSPipeCategory) {
      self.gameOver()
    }
        
    if collision == (FSPlayerCategory | FSBoundaryCategory) {
      if bird.position.y < 150 {
        gameOver()
      }
    }
  }
    
  // #pragma mark - Touch Events
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    if state == .FSGameStateStarting {
      state = .FSGameStatePlaying
            
      instructions.hidden = true
      bird.physicsBody?.affectedByGravity = true
      bird.physicsBody?.applyImpulse(CGVectorMake(0, 25))
            
      self.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock {
        self.initPipes()
      }])), withKey: "generator")
        
    } else if state == .FSGameStatePlaying {
      bird.physicsBody?.applyImpulse(CGVectorMake(0, 25))
    }
  }
    
  // #pragma mark - Frames Per Second
  override func update(currentTime: CFTimeInterval) {
    delta = (last_update_time == 0.0) ? 0.0 : currentTime - last_update_time
    last_update_time = currentTime

    if state != .FSGameStateEnded {
      moveBackground()
            
      let velocity_x = bird.physicsBody?.velocity.dx
      let velocity_y = bird.physicsBody?.velocity.dy
            
      if bird.physicsBody?.velocity.dy > 280 {
        bird.physicsBody?.velocity = CGVectorMake(velocity_x!, 280)
      }
            
      bird.zRotation = Float.clamp(-1, max: 0.0, value: velocity_y! * (velocity_y < 0 ? 0.003 : 0.001))
    } else {
      bird.zRotation = CGFloat(M_PI)
      bird.removeAllActions()
    }
  }
    
}
