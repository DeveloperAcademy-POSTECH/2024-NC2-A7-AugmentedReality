//
//  GridPlane.swift
//  AR-Basketball
//
//  Created by zaehorang on 6/20/24.
//

import ARKit

final class GridPlane: SCNNode {
    let node: SCNNode
    var classificationNode: SCNNode?
    
    /// - Tag: VisualizePlane
    init(anchor: ARPlaneAnchor, in sceneView: ARSCNView) {
        // 평면의 경계 직사각형을 시각화하기 위한 노드 생성
        let plane = SCNPlane(width: CGFloat(anchor.planeExtent.width), height: CGFloat(anchor.planeExtent.height))
        node = SCNNode(geometry: plane)
        node.simdPosition = anchor.center
        
        // `SCNPlane`은 로컬 좌표 공간에서 수직으로 정렬되어 있으므로,
        // `ARPlaneAnchor`의 방향에 맞추기 위해 회전시킴
        node.eulerAngles.x = -.pi / 2

        super.init()
        
        setupNodeVisualStyle()

        // 노드를 자식 노드로 추가하여 장면에 나타나게 함
        addChildNode(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNodeVisualStyle() {
        // 경계 시각화를 반투명하게 하여 실제 배치를 명확하게 보여줌
        guard let material = node.geometry?.firstMaterial else {
            fatalError("SCNPlane always has one material")
        }
        
        material.diffuse.contents = UIImage(named: FileNames.Skin.grid)
    }
}
