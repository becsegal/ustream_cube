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
package {
    
    import flash.system.Security;
    import flash.display.*;
    import flash.events.*;
    import flash.net.*;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.ContextMenuBuiltInItems;
    import flash.events.ContextMenuEvent;
    
    import com.becarella.ustream.UStreamCube;
         
    [SWF(width="400", height="400", frameRate="30", backgroundColor="#0000FF")]
    
    /**
     * The Main class for creating a UStreamCube display.  The cube shows a 
     * different UStream channel on each side.  Only the topmost channel is
     * playing at any given time.
     * 
     * Users can navigate by:
     * -- dragging the cube
     * -- double clicking the 
     * -- right click and choose a channel from the context menu
     *
     * Pass in channel ids as comma separated values with the name cids
     * Example: UStreamCube.swf?cids=1041782,522594,440966,965158,43162,1909916
     */
    public class Main extends Sprite {
        
        private var cube:UStreamCube;
        
        
        /** 
         * Initialize the cube with channels passed in from the flashvars
         */
        public function Main() {
            trace("Loading UStream Cube");
            trace("Stage size: " + stage.stageWidth + " x " + stage.stageHeight);
            var cubeSize:int =stage.stageWidth;
            cube = new UStreamCube(cubeSize);
            cube.z = cubeSize;
            cube.x = cubeSize/2;
            cube.y = cubeSize/2;
            
            // Grab channel ids from the flashvars and 
            // setup the cube channels
            var cids:String = loaderInfo.parameters.cids;            
            if (cids) {
                var cidList:Array = cids.split(",");
                for (var i:int = 0; i<cidList.length && i < 6; i++) {
                    cube.loadChannel(i, cidList[i]);
                }
            }
            
            addChild(cube);
            initCubeMenu();
        }    
        
        
        /** 
         * Setup the context menu with channel navigation and a link to the source code
         */
        private function initCubeMenu() : void {
            var navMenu:ContextMenu = new ContextMenu();
            navMenu.hideBuiltInItems();
            for (var i:int = 0; i<6; i++) {
                var item:ContextMenuItem = new ContextMenuItem("Channel " + (i+1));
                navMenu.customItems.push(item);
            }
            
            navMenu.customItems[0].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
                                                    function(e:Event):void { showPlane(0); });
                                                    
            navMenu.customItems[1].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
                                                    function(e:Event):void { showPlane(1); });
                                                    
            navMenu.customItems[2].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
                                                    function(e:Event):void { showPlane(2); });
                                                    
            navMenu.customItems[3].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
                                                    function(e:Event):void { showPlane(3); });
                                                    
            navMenu.customItems[4].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
                                                    function(e:Event):void { showPlane(4);  });
                                                    
            navMenu.customItems[5].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
                                                    function(e:Event):void { showPlane(5); });
            
            item = new ContextMenuItem("View Source", true);
            item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, viewSource);
            navMenu.customItems.push(item);
            
            cube.contextMenu = navMenu;
        }
        
        
        /** 
         * Callback from context menu, rotate to the specified plane
         */
        private function showPlane(side:int) : void {
            cube.rotateToPlane(side);
        }
        
        
        /** 
         * Open source code @ github in a new browser window 
         */
        private function viewSource(event:ContextMenuEvent) : void {
            navigateToURL(new URLRequest("http://github.com/becarella/ustream_cube/"), "_blank");
        }
    }
}