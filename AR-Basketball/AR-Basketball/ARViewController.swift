//
//  ARViewController.swift
//  AR-Basketball
//
//  Created by zaehorang on 6/20/24.
//

import ARKit
import SceneKit
import UIKit

class ARViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    private var gridNode: SCNNode? // 그리드 노드를 추적하는 변수
    private var gridAdded = false // 그리드가 추가되었는지 여부를 추적하는 플래그
    private var basketballBoardAdded = false // 농구 골대가 추가되었는지 여부를 추적하는 플래그
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ARSCNView의 delegate 설정
        sceneView.delegate = self
        
        // fps 및 타이밍 정보와 같은 통계를 표시
        sceneView.showsStatistics = false
        
        // 기본 조명을 자동으로 활성화
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupConfiguration() // AR 세션 구성 설정
        registerInitialGestureRecognizer() // 제스처 인식기 등록
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause() // 세션 일시 중지
    }
    
    // AR 세션 구성 설정
    private func setupConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] // 평면 감지 설정
        
        // 화면이 일정 시간 후 어두워지지 않도록 방지
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 세션 실행
        sceneView.session.run(configuration)
    }
    
    // 초기 제스처 인식기 등록
    private func registerInitialGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFirstTap(_:)))
        sceneView.addGestureRecognizer(tap)
    }

    // 첫 번째 탭 처리
    @objc func handleFirstTap(_ sender: UIGestureRecognizer) {
        removeGrid() // 그리드 제거
        
        guard !basketballBoardAdded else { return } // 이미 엔터티가 생성된 경우 메서드 종료
        
        basketballBoardAdded = true // 엔터티 생성 플래그 설정
        
        // 기존 제스처 인식기 제거
        if let tapGesture = sender as? UITapGestureRecognizer {
            sceneView.removeGestureRecognizer(tapGesture)
        }
        
        let tapLocation = sender.location(in: sceneView)
        
        // ARKit의 raycastQuery는 2D 공간에서 터치하는 지점을 3D 좌표로 변환
        guard let query = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal) else { return }
        let results = sceneView.session.raycast(query)
        
        guard let hitResult = results.first else { return }
        
        // 각 씬을 로드하고 노드를 추가
        loadAndAddNode(FileNames.Scenes.basketballBoard, hitResult: hitResult)
        loadAndAddNode(FileNames.Scenes.basketballRing, hitResult: hitResult)
        loadAndAddNode(FileNames.Scenes.basketballFloor, hitResult: hitResult, applyMaterial: true, materialName: FileNames.Skin.floor)
    }
    
    // 씬을 로드하고 노드를 추가하는 함수
    private func loadAndAddNode(_ sceneName: String, hitResult: ARRaycastResult, applyMaterial: Bool = false, materialName: String? = nil) {
        guard let scene = SCNScene(named: sceneName) else {
            print("\(sceneName) 로드 문제")
            return
        }
        addNodeInScene(scene, hitResult: hitResult, applyMaterial: applyMaterial, materialName: materialName)
    }
    
    // 노드를 씬에 추가하는 함수
    private func addNodeInScene(_ scene: SCNScene, hitResult: ARRaycastResult, applyMaterial: Bool = false, materialName: String? = nil) {
        scene.rootNode.childNodes.forEach { node in
            node.position = SCNVector3(
                x: node.position.x + hitResult.worldTransform.columns.3.x,
                y: node.position.y + hitResult.worldTransform.columns.3.y,
                z: node.position.z + hitResult.worldTransform.columns.3.z
            )
            
            let physicsShape = SCNPhysicsShape(node: node, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
            let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
            node.physicsBody = physicsBody
            
            // 특정 노드에만 material을 추가하는 조건
            if applyMaterial, let materialName = materialName {
                let material = SCNMaterial()
                material.diffuse.contents = UIImage(named: materialName)
                node.geometry?.materials = [material]
            }
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    // 그리드 노드를 제거하는 함수
    private func removeGrid() {
        gridNode?.removeFromParentNode()
    }
}

extension ARViewController: ARSCNViewDelegate {
    
    /// - Tag: PlaceARContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 평면 탐지로 발견된 앵커에만 콘텐츠 배치
        guard !gridAdded, let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 평면 기하 구조와 경계를 시각화하는 사용자 정의 객체 생성
        let plane = GridPlane(anchor: planeAnchor, in: sceneView)
        
        // ARKit이 관리하는 노드에 시각화를 추가하여 평면 앵커의 변화 추적
        node.addChildNode(plane)
        
        // 그리드 노드를 추적
        gridNode = plane
        gridAdded = true // 플래그 설정하여 추가적인 그리드 추가 방지
    }
    
    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // `renderer(_:didAdd:for:)`에 의해 설정된 앵커와 노드만 업데이트
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let plane = node.childNodes.first as? GridPlane else { return }
        
        // 앵커의 새로운 추정 모양으로 ARSCNPlaneGeometry 업데이트
        if let planeGeometry = plane.node.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
        
        // 앵커의 새로운 경계 사각형으로 경계 시각화 업데이트
        if let extentGeometry = plane.node.geometry as? SCNPlane {
            extentGeometry.width = CGFloat(planeAnchor.planeExtent.width)
            extentGeometry.height = CGFloat(planeAnchor.planeExtent.height)
            plane.node.simdPosition = planeAnchor.center
        }
    }
}
