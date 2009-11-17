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

    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.*;
    import flash.net.URLRequest;
    import flash.utils.getTimer;
    import flash.system.Security;
    import flash.text.TextField;
    import flash.text.TextFormat;


    /** 
     * A plane for the UStreamCube that shows a UStream channel
     * and the video's title.
     *
     * UStream viewer built on the UStream Flash API
     * See: http://developer.ustream.tv/external/flash/index.html
     */
    public class UStreamPlane extends Sprite {
        private var loader:Loader
        private var viewer:*; // tv.ustream.viewer.logic.Logic
        private var _channel:String; // channel to play
        private var _playing:Boolean = false;
        private var online:Boolean = false;
        
        private var label:TextField = new TextField();

        private var size:int;
        
        private var lastClickTime:int = 0;

        /** 
         * Create a new plane with the given size and play the given channel 
         *
         * @param width and height of the plane
         * @param channel id (optional)
         * @param loader with ustream rsl preloaded (optional)
         */
        public function UStreamPlane(size:int, channel:String = null, loader:Loader = null) {
            // we have to allow the logic loaded from ustream.tv 
            // to access the stage and loaderInfo
            Security.allowDomain('*');
            
            this.size = size;
            this.channel = channel;
            this.loader = loader;
            
            _playing = false;
            
            fillBackground();
            initLabel();

            // Next, create a Loader object, and set up a listener 
            // to watch the loader progress
            if (!loader) {
                loader = new Loader();
                loader.contentLoaderInfo.addEventListener("complete", onComplete);
                loader.load(new URLRequest('http://www.ustream.tv/flash/viewer.rsl.swf'));
            } else {
                onComplete();
            }
        }
        
        
        
        /**
         * Set the channel and start playback if possible.
         * The channel consists of a brand id and channel code
         * The brand id (integer) and the channel code (string) is concatenated 
         * with a slash character, like: 49/test
         *
         * If using a UStream channel, you can skip the brand id and slash.
         */
        public function set channel(value:String) : void {            
            _channel = value;
            if (viewer) {
                try {
                    viewer.createChannel(_channel);
                } catch (e:Error) {
                    trace("[UStreamPlane] error: " + e);
                }
            }
        }
        
        
        /** 
         * Play or pause the stream
         */
        public function set playing(value:Boolean) : void {
            _playing = value;
            if (viewer && viewer.playing == _playing) { return; }
            if (viewer) {
                viewer.playing = _playing;
            }
            updateLabel();
        }
        
        
        /**
         * RSL loaded. Setup the viewer.
         */
        private function onComplete(event:Event = null) : void {
            loader.contentLoaderInfo.removeEventListener("complete", onComplete);
            
            // After we made sure that all the required classes are loaded 
            // from the logic SWF we can initiate the Logic class.
            var Viewer:Class = loader.contentLoaderInfo.applicationDomain.getDefinition('tv.ustream.viewer.logic.Logic') as Class;
            viewer = new Viewer();
            playing = _playing;
            Viewer.debug = false;
            
            viewer.display.width = size;
            viewer.display.height = size;
            viewer.display.x = -size/2;
            viewer.display.y = -size/2;
            
            viewer.addEventListener("createChannel", onCreateChannel);
            
            //viewer.display.doubleClickEnabled = true;
            viewer.display.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick); // not working, why??
            viewer.display.addEventListener(MouseEvent.CLICK, onClick); // use a click event to fake doubleClick for now

            addChild(viewer.display);

            if (_channel) {
                channel = _channel;
            }
        }
        
        private function onCreateChannel(event:Event) : void {
            viewer.removeEventListener("createChannel", onCreateChannel);
            viewer.channel.addEventListener("offline", onOffline);
            viewer.channel.addEventListener("online", onOnline);
            viewer.channel.addEventListener("data", onData);
            updateLabel();
        }
        
        private function onData(event:Event) : void {
            viewer.channel.removeEventListener("data", onData);
            updateLabel();
        }
        
        private function onOffline(event:Event) : void {
            online = false;
            updateLabel();
        }
        
        private function onOnline(event:Event) : void {
            playing = _playing;
            online = true;
            updateLabel();
        }
        
        
        /** 
         * User double clicked on the UStream video, relay the event
         *
         * NOTE: this is never called, but I'm not sure why.  I've 
         * implemented a fake doubleClick event in the onClick handler
         * until I get a proper doubleClick working
         */
        private function onDoubleClick(event:MouseEvent) : void {
            dispatchEvent(event);
        }
        
        
        /**
         * Fake a MouseEvent.DOUBLE_CLICK by looking for two 
         * click events that are less than a second apart.
         */
        private function onClick(event:MouseEvent) : void {
            var clickTime:int = getTimer();
            if (clickTime - lastClickTime < 300) {
                dispatchEvent(new Event(MouseEvent.DOUBLE_CLICK));
            } 
            lastClickTime = clickTime;
        }
        
        
        /** 
         * Fill the square plane with a background color
         */
        private function fillBackground() : void {
            graphics.lineStyle(2.0, 0xCCCCCC);
            graphics.beginFill(0x000000, 1);
            graphics.drawRect(-size/2,-size/2,size,size);
            graphics.endFill();
        }
        

        /** 
         * Initialize the label show in the upper right corner
         */
        private function initLabel() : void {
            label.x = -size/2 + 5;
            label.y = -size/2 + 5;
            label.width = size - 10;
            label.selectable = false;
            label.mouseEnabled = false;

            var format:TextFormat = new TextFormat();
            format.font = "Verdana";
            format.color = 0xFFFFFF;
            format.size = 16;

            label.defaultTextFormat = format;
            updateLabel();
            addChild(label);
        }
        
        
        /** 
         * Update the label to show the current playback
         * state: playing, paused, or offline
         */
        private function updateLabel() : void {
            if (!online && (viewer && viewer.recorded && !viewer.recorded.playing)) {
                label.text = "Offline";
            } else if (_playing) {
                label.text = "Playing";
            } else {
                label.text = "Paused";
            }
            if (viewer && viewer.channel) {
                label.appendText(" - " + viewer.channel.title);
            }
        }
                
        
    }
}