import PlaygroundSupport

import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError()
}

// 视图大小
let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
// 创建一个MTKView视图
let view = MTKView(frame: frame, device: device)

view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 0.7)

// 数据缓冲分配
let allocator = MTKMeshBufferAllocator(device: device)

let mdlMesh = MDLMesh(sphereWithExtent: [0.25, 0.25, 0.75], segments: [100, 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)

let mesh = try MTKMesh(mesh: mdlMesh, device: device)



// 创建命令队列
guard let commandQueue = device.makeCommandQueue() else {
  fatalError("Could not create a command queue")
}

// shader代码字符串
let shader = """
#include <metal_stdlib>
using namespace metal;
struct VertexIn {
  float4 position [[ attribute(0) ]];
};
vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
  return vertex_in.position;
}
fragment float4 fragment_main() {
  return float4(0, 0, 0, 1);
}
"""

// matel库
let library = try device.makeLibrary(source: shader, options: nil)
// 顶点shader函数
let vertexFunction = library.makeFunction(name: "vertex_main")
// 像素shader函数
let fragmentFunction = library.makeFunction(name: "fragment_main")


// 流水线状态描述
let pipelineDescriptor = MTLRenderPipelineDescriptor()
// 我们设置颜色为32位色，顺序为蓝/绿/红/不透明通道
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
// 设置顶点shader函数
pipelineDescriptor.vertexFunction = vertexFunction
// 设置像素shader函数
pipelineDescriptor.fragmentFunction = fragmentFunction

// 设置顶点布局，加载球体模型时，Model I/O会自动创建一个顶点描述，我们直接用即可
pipelineDescriptor.vertexDescriptor =
  MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)

// 创建流水线状态对象
let pipelineState =
  try device.makeRenderPipelineState(descriptor: pipelineDescriptor)


// 创建命令缓冲，它将会存储你给GPU的所有命令
guard let commandBuffer = commandQueue.makeCommandBuffer(),
  // 保存一个渲染pass描述器，描述器将会保存渲染目标的信息，叫做：attachments。
  // 每个attachment会保存渲染目标纹理信息等。渲染pass描述通常用来创建命令编码器。
  let renderPassDescriptor = view.currentRenderPassDescriptor,
  // 创建一个命令编码器，命令编码器会保存你设置给它的各个命令，并发送给GPU。
  let renderEncoder =
  commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
  else {  fatalError() }

// 设置流水线状态对象PSO
renderEncoder.setRenderPipelineState(pipelineState)

// 设置顶点缓冲，通过球体的mesh获得
renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer,
                              offset: 0, index: 0)

// 一个mesh通常是由多个子mesh组成，它们通过不同的材质组来分组。
// 比如你要渲染一辆宝马汽车，它可能会有汽车身体和轮胎等多个子mesh组成。
// 这里球体mesh，我们只需要简单使用第一个子mesh即可。
guard let submesh = mesh.submeshes.first else {
  fatalError()
}

// 渲染球体mesh，这里用了一个draw call。这里你只要指示GPU来渲染一个由三角形
// 组成的顶点缓冲，它们通过子mesh的索引来排列好顶点的正确顺序，不过，
// 这个代码不执行实际的渲染，直到GPU收到命令缓冲的所有命令为止，才会逐步执行
renderEncoder.drawIndexedPrimitives(type: .triangle,
                                    indexCount: submesh.indexCount,
                                    indexType: submesh.indexType,
                                    indexBuffer: submesh.indexBuffer.buffer,
                                    indexBufferOffset: 0)


// 命令记录完成
renderEncoder.endEncoding()
// 获取MTKView的drawable，这个是你输出到屏幕的纹理
guard let drawable = view.currentDrawable else {
  fatalError()
}
// 通知命令缓冲来呈现MTKView的drawable
commandBuffer.present(drawable)
// 命令缓冲提交到GPU
commandBuffer.commit()

// 把MTKView对象设置到Playgroud的页面中
PlaygroundPage.current.liveView = view
