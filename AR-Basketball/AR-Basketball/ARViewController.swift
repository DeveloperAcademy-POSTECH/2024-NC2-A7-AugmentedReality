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
    
    private var gridAdded = false // 그리드가 추가되었는지 여부를 추적하는 플래그
    
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 세션 일시 중지
        sceneView.session.pause()
    }
    
    // AR 세션 구성 설정
    func setupConfiguration() {
        // 세션 구성 생성
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] // 평면 감지
        
        // 화면이 일정 시간 후 어두워지지 않도록 방지
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 세션 실행
        sceneView.session.run(configuration)
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
