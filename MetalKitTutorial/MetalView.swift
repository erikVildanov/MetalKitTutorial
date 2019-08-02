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

class MetalView: UIView {
    
    var vertex_buffer: MTLBuffer!
    var uniform_buffer: MTLBuffer!
    var rps: MTLRenderPipelineState! = nil
    
    let mtkView = MTKView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
        setupPropety()
        createBuffer()
        registerShaders()
    }
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeView() {
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mtkView)
        addConstraint(NSLayoutConstraint(item: mtkView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: mtkView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: mtkView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: mtkView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
    }
    
    func setupPropety() {
        let device = MTLCreateSystemDefaultDevice()!
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = self
    }
    
    func createBuffer() {
        let vertex_data = [Vertex(position: [-1.0, -1.0, 0.0, 1.0], color: [1, 0, 0, 1]),
                           Vertex(position: [ 1.0, -1.0, 0.0, 1.0], color: [0, 1, 0, 1]),
                           Vertex(position: [ 0.0,  1.0, 0.0, 1.0], color: [0, 0, 1, 1])]
        vertex_buffer = mtkView.device!.makeBuffer(bytes: vertex_data, length: MemoryLayout<Vertex>.size * 3, options:[])
        
        uniform_buffer = mtkView.device!.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
        let bufferPointer = uniform_buffer.contents()
        memcpy(bufferPointer, Matrix().modelMatrix(matrix: Matrix()).m, MemoryLayout<Float>.size * 16)
    }
    
    func registerShaders() {
        let library = mtkView.device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            try rps = mtkView.device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            print("\(error)")
        }
    }
    
    func sendToGPU() {
        if let rpd = mtkView.currentRenderPassDescriptor, let drawable = mtkView.currentDrawable {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
            let command_buffer = mtkView.device!.makeCommandQueue()!.makeCommandBuffer()
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
}

extension MetalView: MTKViewDelegate {
    func draw(in view: MTKView) {
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        sendToGPU()
    }
    
    
}
