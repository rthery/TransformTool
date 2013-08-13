/*
Copyright (c) 2010 Trevor McCauley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
*/
package com.senocular.display.transform {
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventPhase;
	
	/**
	 * Draws a line between two other controls (DisplayObject instances).
	 * ControlConnector styling does not support fill styles.
	 * @author Trevor McCauley
	 */
	public class ControlConnector extends Control {
		
		/**
		 * The first of two control objects that a this ControlConnector
		 * instance draws a line between.  Both control1 and control2 need
		 * to be valid objects before a line is drawn to connect them.
		 */
		public function get control1():DisplayObject { 
			return _control1; 
		}
		
		public function set control1(value:DisplayObject):void {
			if (value == _control1){
				return;
			}
			
			if (_control1){
				_control1.removeEventListener(Event.ADDED_TO_STAGE, redraw, false);
			}
			
			_control1 = value;
			
			if (_control1){
				// we presume the control will redraw itself
				// when added to the stage along with REDRAW events
				// as with REDRAW, priority is lowered
				_control1.addEventListener(Event.ADDED_TO_STAGE, redraw, false, -1, true);
				
				if (tool != null){
					redraw(null);
				}
			}
		}
		private var _control1:DisplayObject;
		
		/**
		 * The second of two control objects that a this ControlConnector
		 * instance draws a line between.  Both control1 and control2 need
		 * to be valid objects before a line is drawn to connect them.
		 */
		public function get control2():DisplayObject {
			return _control2; 
		}
		public function set control2(value:DisplayObject):void { 
			if (value == _control2){
				return;
			}
			
			if (_control2){
				_control2.removeEventListener(Event.ADDED_TO_STAGE, redraw, false);
			}
			
			_control2 = value;
			
			if (_control2){
				// we presume the control will redraw itself
				// when added to the stage along with REDRAW events
				// as with REDRAW, priority is lowered
				_control2.addEventListener(Event.ADDED_TO_STAGE, redraw, false, -1, true);
				
				if (tool != null){
					redraw(null);
				}
			}
		}
		private var _control2:DisplayObject;
		
		/**
		 * Constructor for creating new ControlConnector instances.
		 * @param	control1 One of two controls the connector line is drawn
		 * between.
		 * @param	control2 The second of two controls the connector line
		 * is drawn between.
		 */
		public function ControlConnector(control1:DisplayObject = null, control2:DisplayObject = null){
			super();
			if (control1 != null) this.control1 = control1;
			if (control2 != null) this.control2 = control2;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function setupTool():void {
			if (tool){
				// redraw events need to be added at a lower priority
				// allowing the two controls being connected to each
				// redraw before this ControlConnector instance.
				tool.addEventListener(TransformTool.REDRAW, redraw, false, -1);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function redraw(event:Event):void {
			super.redraw(event);
			
			if (control1 == null || control2 == null){
				graphics.clear();
				return;
			}
			
			with (graphics){
				clear();
				lineStyle(this.lineThickness, this.lineColor, this.lineAlpha);
				moveTo(control1.x, control1.y);
				lineTo(control2.x, control2.y);
			}
		}
	}
}