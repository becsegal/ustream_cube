/**
 * Copyright 2009 Becky Carella
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.becarella.ustream {
    
    import flash.display.*;
    import flash.events.*;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    
    import com.theflashblog.fp10.SimpleZSorter;
    import com.unitzeroone.fp10.ArcBall;
    
    
    /** 
     * UStreamCube can show up to 6 UStream channels, 1 per side
     * Based in part on the examples from 
     * http://www.unitzeroone.com/blog/2009/09/08/source-better-flash-10-3d-interaction-arcball/
     */
    public class UStreamCube extends Sprite {
        
        public static const NUM_PLANES:int = 6;
        public static const FRONT:int = 0;
        public static const LEFT:int = 1;
        public static const BACK:int = 2;
        public static const RIGHT:int = 3;
        public static const TOP:int = 4;
        public static const BOTTOM:int = 5;
        public var planes:Array;
        
        public var planeNames:Array = ["front",  "left", "back","right", "top", "bottom"];
        
        private var size:int;
        private var halfSize:int;
        
        private var arcBall:ArcBall;
        
        private var endTurnRotation:Matrix3D;
        private var startTurnRotation:Matrix3D;
        private static const TURN_STEPS:Number = 10;
        private var currentStep:int = 0;
        
        
        
        /** 
         * Create a cube with the specified size for the height and width
         */
        public function UStreamCube(size:int) {
            this.size = size;
            halfSize = size/2;

            planes = new Array();
            for (var i:int = 0; i<NUM_PLANES; i++) {
                planes[i] = new UStreamPlane(size);
                planes[i].name = planeNames[i];
                planes[i].doubleClickEnabled = true;
                planes[i].addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
                addChild(planes[i]);
            }

            planes[TOP].rotationX = -90;
            planes[TOP].y = -halfSize;
            
            planes[BOTTOM].rotationX = 90;
            planes[BOTTOM].y = halfSize;
            
            planes[LEFT].x = -halfSize;
            planes[LEFT].rotationY = 90;
            
            planes[RIGHT].x = halfSize;
            planes[RIGHT].rotationY = -90;
            
            planes[BACK].z = halfSize;
            planes[BACK].rotationY = 180;
            
            planes[FRONT].z = -halfSize;
            planes[FRONT].playing = true;
            
            arcBall = new ArcBall(this);
            arcBall.addEventListener("dragged", sort);
            addEventListener(Event.ADDED, sort);
        }    
        
        
        /**
         * Load the specified UStream channel on the given side
         */
        public function loadChannel(side:int, channel:String) : void {
            if (side >= 0 && side < 6) {
                planes[side].channel = channel;
            }
        }
        

        /** 
         * Sort the planes and make sure only the top plane
         * has video playing.
         */
        private function sort(event:Event = null) : void {
            SimpleZSorter.sortClips(this,true);
            var topIndex:int = numChildren - 1;
            for each (var plane:UStreamPlane in planes) {
                if (getChildIndex(plane) == topIndex) {
                    plane.playing = true;
                } else {
                    plane.playing = false;
                }
            }
        }
        
        
        /**
         * Turn to the plane that dispatched the event
         */
        private function onDoubleClick(event:Event) : void {
            var planeIndex:int = planeNames.indexOf(event.target.name);
            rotateToPlane(planeIndex);
        }
        
        
        /**
         * Kick off the transition animation to the target rotation.
         */
        public function rotateToPlane(index:int) : void {
            var targetTurnRotation:Vector3D = null;
            switch (index) {
                case TOP:
                    targetTurnRotation = new Vector3D(90, 0, 0);
                    break;
                case BOTTOM:
                    targetTurnRotation = new Vector3D(-90, 0, 0);
                    break;
                case BACK:
                    targetTurnRotation = new Vector3D(0, 180, 0);
                    break;
                case FRONT:
                    targetTurnRotation = new Vector3D(0, 0, 0);
                    break;
                case LEFT:
                    targetTurnRotation = new Vector3D(90, -90, -90);
                    break;
                case RIGHT:
                    targetTurnRotation = new Vector3D(90, 90, 90);
                    break;
            }
            if (null == targetTurnRotation) { return; }
             
            // CHEAT: setup a dummy object with the desired
            // target rotation and position and use its matrix
            // as the turn target
            var dummy:Sprite = new Sprite();
            dummy.rotationX = targetTurnRotation.x;
            dummy.rotationY = targetTurnRotation.y;
            dummy.rotationZ = targetTurnRotation.z;
            dummy.x = x;
            dummy.y = y;
            dummy.z = z;
            endTurnRotation = dummy.transform.matrix3D.clone();
            
            startTurnRotation = transform.matrix3D.clone();

            dummy = null;
            currentStep = 0;
            addEventListener(Event.ENTER_FRAME, rotate);
        }
        
        
        /** 
         * Rotate the cube by 1 step
         */
        private function rotate(event:Event) : void {
            currentStep++;
            transform.matrix3D = Matrix3D.interpolate(startTurnRotation, endTurnRotation, currentStep / TURN_STEPS);
            sort();
            if (TURN_STEPS == currentStep) {
                removeEventListener(Event.ENTER_FRAME, rotate);
            }
        }
    }
}