//
//  MetalView.swift
//  MetalKitCh08
//
//  Created by Erik Vildanov on 02/08/2019.
//  Copyright © 2019 Erik Vildanov. All rights reserved.
//

import UIKit
import MetalKit

class MetalView: UIView {
    
    var index_buffer: MTLBuffer!
    var vertex_buffer: MTLBuffer!
    var uniform_buffer: MTLBuffer!
    var rps: MTLRenderPipelineState! = nil
    
    var rotation: Float = 0
    
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
        let vertex_data = [
            Vertex(pos: [-1.0, -1.0,  1.0, 1.0], col: [1, 0, 0, 1]),
            Vertex(pos: [ 1.0, -1.0,  1.0, 1.0], col: [0, 1, 0, 1]),
            Vertex(pos: [ 1.0,  1.0,  1.0, 1.0], col: [0, 0, 1, 1]),
            Vertex(pos: [-1.0,  1.0,  1.0, 1.0], col: [1, 1, 1, 1]),
            Vertex(pos: [-1.0, -1.0, -1.0, 1.0], col: [0, 0, 1, 1]),
            Vertex(pos: [ 1.0, -1.0, -1.0, 1.0], col: [1, 1, 1, 1]),
            Vertex(pos: [ 1.0,  1.0, -1.0, 1.0], col: [1, 0, 0, 1]),
            Vertex(pos: [-1.0,  1.0, -1.0, 1.0], col: [0, 1, 0, 1])
        ]
        
        let index_data: [UInt16] = [
            0, 1, 2, 2, 3, 0,   // front
            
            1, 5, 6, 6, 2, 1,   // right
            
            3, 2, 6, 6, 7, 3,   // top
            
            4, 5, 1, 1, 0, 4,   // bottom
            
            4, 0, 3, 3, 7, 4,   // left
            
            7, 6, 5, 5, 4, 7,   // back
            
        ]
        index_buffer = mtkView.device!.makeBuffer(bytes: index_data, length: MemoryLayout<UInt16>.size * index_data.count , options: [])
        
        
        vertex_buffer = mtkView.device!.makeBuffer(bytes: vertex_data, length: MemoryLayout<Vertex>.size * vertex_data.count, options:[])
        
        uniform_buffer = mtkView.device!.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
        let bufferPointer = uniform_buffer.contents()
        
        let aspect = Float(UIScreen.main.bounds.width / UIScreen.main.bounds.height)
        let projMatrix = projectionMatrix(near: 1, far: 100, aspect: aspect, fovy: 1.1)
        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix(), modelMatrix()))
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
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
            
            command_encoder!.setFrontFacing(.counterClockwise)
            command_encoder!.setCullMode(.back)
            
            command_encoder!.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            command_encoder!.setVertexBuffer(uniform_buffer, offset: 0, index: 1)
            command_encoder!.drawIndexedPrimitives(type: .triangle, indexCount: index_buffer.length / MemoryLayout<UInt16>.size, indexType: .uint16, indexBuffer: index_buffer, indexBufferOffset: 0)
            command_encoder!.endEncoding()
            command_buffer!.present(drawable)
            command_buffer!.commit()
        }
    }
    
    func modelMatrix() -> matrix_float4x4 {
        let scaled = scalingMatrix(scale: 0.5)
        let rotatedY = rotationMatrix(angle: Float.pi/4, axis: float3(0, 1, 0))
        let rotatedX = rotationMatrix(angle: Float.pi/4, axis: float3(1, 0, 0))
        return matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
    }
    
    func update() {
        let scaled = scalingMatrix(scale: 0.5)
        rotation += 1 / 100 * Float.pi/4
        let rotatedY = rotationMatrix(angle: rotation, axis: float3(0, 1, 0))
        let rotatedX = rotationMatrix(angle: Float.pi/4, axis: float3(1, 0, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
        let cameraPosition = vector_float3(0, 0, -3)
        let viewMatrix = translationMatrix(position: cameraPosition)
        let aspect = Float(UIScreen.main.bounds.width / UIScreen.main.bounds.height)
        let projMatrix = projectionMatrix(near: 0, far: 10, aspect: aspect, fovy: 1)
        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
        let bufferPointer = uniform_buffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
    }
    
}

extension MetalView: MTKViewDelegate {
    func draw(in view: MTKView) {
        sendToGPU()
        update()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    
}
