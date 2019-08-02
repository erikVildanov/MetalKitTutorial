//
//  MetalView.swift
//  MetalKitTutorial
//
//  Created by Erik Vildanov on 02/08/2019.
//  Copyright © 2019 Erik Vildanov. All rights reserved.
//

import UIKit
import MetalKit

class MetalView: MTKView {
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func render() {
        let device = MTLCreateSystemDefaultDevice()!
        self.device = device
        let rpd = MTLRenderPassDescriptor()
        let bleen = MTLClearColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        rpd.colorAttachments[0].texture = currentDrawable!.texture
        rpd.colorAttachments[0].clearColor = bleen
        rpd.colorAttachments[0].loadAction = .clear
        guard let commandQueue = device.makeCommandQueue(),
        let commandBuffer = commandQueue.makeCommandBuffer(),
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)  else { return }
        encoder.endEncoding()
        commandBuffer.present(currentDrawable!)
        commandBuffer.commit()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        render()
    }
}
