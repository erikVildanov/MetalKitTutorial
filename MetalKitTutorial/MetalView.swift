//
//  MetalView.swift
//  MetalKitTutorial
//
//  Created by Erik Vildanov on 02/08/2019.
//  Copyright © 2019 Erik Vildanov. All rights reserved.
//

import UIKit
import MetalKit

//vector_float4 x = 1.0f;         // x = { 1, 1, 1, 1 }.
//
//vector_float3 y = { 1, 2, 3 };  // y = { 1, 2, 3 }.
//
//x.xyz = y.zyx;                  // x = { 1/3, 1/2, 1, 1 }.
//
//x.w = 0;                        // x = { 1/4, 1/3, 1/2, 0 }.

struct Vertex {
    var position: vector_float4
    var color: vector_float4
}

class MetalView: MTKView {
    
    var vertex_buffer: MTLBuffer!
    var uniform_buffer: MTLBuffer!
    var rps: MTLRenderPipelineState! = nil
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func render() {
        device = MTLCreateSystemDefaultDevice()
        createBuffer()
        registerShaders()
        sendToGPU()
    }
    
    func createBuffer() {
        let vertex_data = [Vertex(position: [-1.0, -1.0, 0.0, 1.0], color: [1, 0, 0, 1]),
                           Vertex(position: [ 1.0, -1.0, 0.0, 1.0], color: [0, 1, 0, 1]),
                           Vertex(position: [ 0.0,  1.0, 0.0, 1.0], color: [0, 0, 1, 1])]
        vertex_buffer = device!.makeBuffer(bytes: vertex_data, length: MemoryLayout<Vertex>.size * 3, options:[])
        
        uniform_buffer = device!.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
        let bufferPointer = uniform_buffer.contents()
        memcpy(bufferPointer, Matrix().modelMatrix(matrix: Matrix()).m, MemoryLayout<Float>.size * 16)
    }
    
    func registerShaders() {
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            try rps = device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            print("\(error)")
        }
    }
    
    func sendToGPU() {
        if let rpd = currentRenderPassDescriptor, let drawable = currentDrawable {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
            let command_buffer = device!.makeCommandQueue()!.makeCommandBuffer()
            let command_encoder = command_buffer!.makeRenderCommandEncoder(descriptor: rpd)
            command_encoder!.setRenderPipelineState(rps)
            command_encoder!.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            command_encoder!.setVertexBuffer(uniform_buffer, offset: 0, index: 1)
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
