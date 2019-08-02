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
        device = MTLCreateSystemDefaultDevice()
        
        let vertex_data:[Float] = [-1.0, -1.0, 0.0, 1.0,
                                   1.0, -1.0, 0.0, 1.0,
                                   0.0,  1.0, 0.0, 1.0]
        let data_size = vertex_data.count * MemoryLayout<Float>.size
        let vertex_buffer = device!.makeBuffer(bytes: vertex_data, length: data_size, options: [])
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let rps = try! device!.makeRenderPipelineState(descriptor: rpld)
        
        if let rpd = currentRenderPassDescriptor, let drawable = currentDrawable {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0.5, 1.0)
            let command_buffer = device!.makeCommandQueue()!.makeCommandBuffer()
            let command_encoder = command_buffer!.makeRenderCommandEncoder(descriptor: rpd)
            
            command_encoder!.setRenderPipelineState(rps)
            command_encoder!.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            command_encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            
            command_encoder!.endEncoding()
            command_buffer!.present(drawable)
            command_buffer!.commit()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        render()
    }
}
