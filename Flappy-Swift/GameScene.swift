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

// Math helpers
extension Float {
    static func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if (value > max) {
            return max
        } else if (value < min) {
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
    var delta = NSTimeInterval(0)
    var last_update_time = NSTimeInterval(0)
    
    // Physics Categories
    let FSBoundaryCategory: UInt32 = 1 << 0
    let FSPlayerCategory: UInt32   = 1 << 1
    let FSPipeCategory: UInt32     = 1 << 2
    let FSGapCategory: UInt32      = 1 << 3
    
    // Game States
    enum FSGameState: Int {
        case FSGameStateStarting
        case FSGameStatePlaying
        case FSGameStateEnded
    }
    
    var state = FSGameState.FSGameStateStarting
    
    // MARK: - SKScene Initializacion
    override func didMoveToView(view: SKView) {
        initWorld()
        initBackground()
        initBird()
        initHUD()
    }
    
    // MARK: - Init Physics
    func initWorld() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: 0.0, y: floor_distance, width: size.width, height: size.height - floor_distance))
        physicsBody?.categoryBitMask = FSBoundaryCategory
        physicsBody?.collisionBitMask = FSPlayerCategory
    }
    
    // MARK: - Init Bird
    func initBird() {
        bird = SKSpriteNode(imageNamed: "bird1")
        bird.position = CGPoint(x: 100.0, y: CGRectGetMidY(frame))
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
        
        bird.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.1)))
    }
    
    // MARK: - Score
    func initHUD() {
        label_score = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        label_score.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMaxY(frame) - 100)
        label_score.text = "0"
        label_score.zPosition = 50
        self.addChild(label_score)
        
        instructions = SKSpriteNode(imageNamed: "TapToStart")
        instructions.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) - 10)
        instructions.zPosition = 50
        addChild(instructions)
    }
    
    // MARK: - Background Functions
    func initBackground() {
        background = SKNode()
        addChild(background)
        
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
    
    // MARK: - Pipes Functions
    func initPipes() {
        let screenSize = UIScreen.mainScreen().bounds
        let isWideScreen = (screenSize.height > 480)
        let bottom = getPipeWithSize(CGSize(width: 62, height: Float.range(40, max: isWideScreen ? 360 : 280)), side: false)
        bottom.position = convertPoint(CGPoint(x: pipe_origin_x, y: CGRectGetMinY(frame) + bottom.size.height/2 + floor_distance), toNode: background)
        bottom.physicsBody = SKPhysicsBody(rectangleOfSize: bottom.size)
        bottom.physicsBody?.categoryBitMask = FSPipeCategory;
        bottom.physicsBody?.contactTestBitMask = FSPlayerCategory;
        bottom.physicsBody?.collisionBitMask = FSPlayerCategory;
        bottom.physicsBody?.dynamic = false
        bottom.zPosition = 20
        background.addChild(bottom)
        
        let threshold = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 10, height: 100))
        threshold.position = convertPoint(CGPoint(x: pipe_origin_x, y: floor_distance + bottom.size.height + threshold.size.height/2), toNode: background)
        threshold.physicsBody = SKPhysicsBody(rectangleOfSize: threshold.size)
        threshold.physicsBody?.categoryBitMask = FSGapCategory
        threshold.physicsBody?.contactTestBitMask = FSPlayerCategory
        threshold.physicsBody?.collisionBitMask = 0
        threshold.physicsBody?.dynamic = false
        threshold.zPosition = 20
        background.addChild(threshold)
        
        let topSize = size.height - bottom.size.height - threshold.size.height - floor_distance
        let top = getPipeWithSize(CGSize(width: 62, height: topSize), side: true)
        top.position = convertPoint(CGPoint(x: pipe_origin_x, y: CGRectGetMaxY(frame) - top.size.height/2), toNode: background)
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
        
        let backgroundTexture = SKTexture(CGImage: tiledBackground.CGImage!)
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
        state = .FSGameStateEnded
        bird.physicsBody?.categoryBitMask = 0
        bird.physicsBody?.collisionBitMask = FSBoundaryCategory
        
        removeActionForKey("generator")
        
        _ = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: Selector("restartGame"), userInfo: nil, repeats: false)
    }
    
    func restartGame() {
        state = .FSGameStateStarting
        bird.removeFromParent()
        background.removeAllChildren()
        background.removeFromParent()
        
        instructions.hidden = false
        
        score = 0
        label_score.text = "0"
        
        initBird()
        initBackground()
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBeginContact(contact: SKPhysicsContact) {
        let collision:UInt32 = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask)
        
        if collision == (FSPlayerCategory | FSGapCategory) {
            score++
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
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if state == .FSGameStateStarting {
            state = .FSGameStatePlaying
            
            instructions.hidden = true
            bird.physicsBody?.affectedByGravity = true
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
            
            runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock {
                self.initPipes()
                }])), withKey: "generator")
            
        } else if state == .FSGameStatePlaying {
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
        }
    }
    
    // MARK: - Frames Per Second
    override func update(currentTime: CFTimeInterval) {
        delta = (last_update_time == 0.0) ? 0.0 : currentTime - last_update_time
        last_update_time = currentTime
        
        if state != .FSGameStateEnded {
            moveBackground()
            
            let velocity_x = bird.physicsBody?.velocity.dx
            let velocity_y = bird.physicsBody?.velocity.dy
            
            if bird.physicsBody?.velocity.dy > 280 {
                bird.physicsBody?.velocity = CGVector(dx: velocity_x!, dy: 280)
            }
            
            bird.zRotation = Float.clamp(-1, max: 0.0, value: velocity_y! * (velocity_y < 0 ? 0.003 : 0.001))
        } else {
            bird.zRotation = CGFloat(M_PI)
            bird.removeAllActions()
        }
    }
    
}
