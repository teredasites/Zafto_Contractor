'use client';

// ZAFTO 3D Floor Plan View — React Three Fiber (SK10)
// Renders extruded walls, door/window openings, floor plane, room labels,
// and trade element sprites. OrbitControls for rotate/pan/zoom.

import React, { useMemo, useRef, useEffect } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import { OrbitControls, Environment } from '@react-three/drei';
import * as THREE from 'three';
import type { FloorPlanData } from '@/lib/sketch-engine/types';
import {
  convertToThreeScene,
  calculateCameraPosition,
} from '@/lib/sketch-engine/three-converter';

interface ThreeDViewProps {
  planData: FloorPlanData;
  width: number;
  height: number;
}

function SceneContent({ planData }: { planData: FloorPlanData }) {
  const { camera } = useThree();
  const controlsRef = useRef<any>(null);

  const sceneData = useMemo(() => convertToThreeScene(planData), [planData]);
  const cameraPos = useMemo(() => calculateCameraPosition(planData), [planData]);

  // Set initial camera position
  useEffect(() => {
    camera.position.set(...cameraPos.position);
    if (controlsRef.current) {
      controlsRef.current.target.set(...cameraPos.target);
      controlsRef.current.update();
    }
  }, [camera, cameraPos]);

  return (
    <>
      {/* Lighting */}
      <ambientLight intensity={0.5} />
      <directionalLight
        position={[200, 300, 200]}
        intensity={0.8}
        castShadow
        shadow-mapSize-width={2048}
        shadow-mapSize-height={2048}
      />
      <directionalLight position={[-100, 200, -100]} intensity={0.3} />

      {/* Environment for reflections */}
      <Environment preset="apartment" background={false} />

      {/* Orbit controls */}
      <OrbitControls
        ref={controlsRef}
        enableDamping
        dampingFactor={0.1}
        minDistance={50}
        maxDistance={2000}
        maxPolarAngle={Math.PI / 2 - 0.05} // prevent going below floor
      />

      {/* Floor plane */}
      {sceneData.floor && <primitive object={sceneData.floor} />}

      {/* Walls */}
      {sceneData.walls.map((wall, i) => (
        <primitive key={`wall-${i}`} object={wall} />
      ))}

      {/* Doors */}
      {sceneData.doors.map((door, i) => (
        <primitive key={`door-${i}`} object={door} />
      ))}

      {/* Windows */}
      {sceneData.windows.map((win, i) => (
        <primitive key={`window-${i}`} object={win} />
      ))}

      {/* Fixtures */}
      {sceneData.fixtures.map((fix, i) => (
        <primitive key={`fix-${i}`} object={fix} />
      ))}

      {/* Room labels (sprites) */}
      {sceneData.roomLabels.map((label, i) => (
        <primitive key={`room-${i}`} object={label} />
      ))}

      {/* Trade elements (sprites) */}
      {sceneData.tradeElements.map((elem, i) => (
        <primitive key={`trade-${i}`} object={elem} />
      ))}

      {/* Ground grid */}
      <gridHelper
        args={[2000, 100, 0xcccccc, 0xe8e8e8]}
        position={[0, -0.5, 0]}
      />
    </>
  );
}

export default function ThreeDView({ planData, width, height }: ThreeDViewProps) {
  return (
    <div
      style={{ width, height }}
      className="bg-gradient-to-b from-gray-100 to-gray-200 rounded-lg overflow-hidden"
    >
      <Canvas
        shadows
        gl={{
          antialias: true,
          toneMapping: THREE.ACESFilmicToneMapping,
          toneMappingExposure: 1.2,
        }}
        camera={{ fov: 50, near: 1, far: 5000 }}
      >
        <SceneContent planData={planData} />
      </Canvas>
    </div>
  );
}
