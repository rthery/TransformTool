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
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * Base class for standard Transform Tool controls.  The base class 
	 * includes basic styling properties and the core framework for 
	 * updates.  For interactive controls, use ControlInteractive. It is
	 * not required for controls to extend the Control class to be used
	 * as a control of the Transform Tool.
	 * @author Trevor McCauley
	 */
	public class Control extends Sprite {
		
		/**
		 * The color to be used for filled shapes in dynamically drawn
		 * control graphics.
		 */
		public function get fillColor():uint { return _fillColor; }
		public function set fillColor(value:uint):void { _fillColor = value; }
		private var _fillColor:uint = 0xFFFFFF;
		
		/**
		 * The color to be used for outlines in dynamically drawn control
		 * graphics.
		 */
		public function get lineColor():uint { return _lineColor; }
		public function set lineColor(value:uint):void { _lineColor = value; }
		private var _lineColor:uint = 0x000000;
		
		/**
		 * The alpha of the color used for filled shapes in dynamically drawn
		 * control graphics.
		 */
		public function get fillAlpha():Number { return _fillAlpha; }
		public function set fillAlpha(value:Number):void { _fillAlpha = value; }
		private var _fillAlpha:Number = 1.0;
		
		/**
		 * The alpha of the color used for outlines in dynamically drawn 
		 * control graphics.
		 */
		public function get lineAlpha():Number { return _lineAlpha; }
		public function set lineAlpha(value:Number):void { _lineAlpha = value; }
		private var _lineAlpha:Number = 1.0;
		
		/**
		 * The thickness used for outlines in dynamically drawn control 
		 * graphics.
		 */
		public function get lineThickness():Number { return _lineThickness; }
		public function set lineThickness(value:Number):void { _lineThickness = value; }
		private var _lineThickness:Number = 0;
		
		/**
		 * A reference to the TransformTool instance the control was placed,
		 * defined in the ADDED_TO_STAGE event.  The control must be a direct
		 * child of a TransformTool instance for it to be recognized.
		 */
		public function get tool():TransformTool {
			return _tool;
		}
		public function set tool(value:TransformTool):void {
			if (value == _tool){
				return;
			}
			
			cleanupTool();
			_tool = value;
			setupTool();
		}
		private var _tool:TransformTool;
		
		/**
		 * Setup steps when defining a new tool value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set tool setter. This is called after
		 * a new tool value is set.
		 */
		protected function setupTool():void {
			if (_tool){
				_tool.addEventListener(TransformTool.REDRAW, redraw);
				_tool.addEventListener(TransformTool.TARGET_CHANGED, targetChanged);
				redraw(null);
			}
		}
		
		/**
		 * Cleanup steps when defining a new tool value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set tool setter.  This is called before
		 * a new tool value is set.
		 */
		protected function cleanupTool():void {
			if (_tool){
				_tool.removeEventListener(TransformTool.REDRAW, redraw);
				_tool.removeEventListener(TransformTool.TARGET_CHANGED, targetChanged);	
			}
		}
		
		/**
		 * Constructor for creating new Control instances.
		 */
		public function Control() {
			super();
			addEventListener(Event.ADDED, added, true); // redraw when child assets added
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		/**
		 * Handler for the Event.ADDED event (capture). This is used to
		 * recognize when child display objects have been added to the
		 * display list so that a call to draw can be made.
		 */
		protected function added(event:Event):void {
			draw();
		}
		
		/**
		 * Handler for the Event.ADDED_TO_STAGE event. By default, this
		 * is used to define the tool reference.  If valid, draw() is
		 * called.
		 */
		protected function addedToStage(event:Event):void {
			var tool:TransformTool = parent as TransformTool;
			if (tool != null){
				this.tool = tool;
				draw();
			}else{
				this.tool = null;
			}
		}
		
		/**
		 * Handler for the Event.REMOVED_FROM_STAGE event. By default, 
		 * this is used to clear the tool reference.
		 */
		protected function removedFromStage(event:Event):void {
			this.tool = null;
		}
		
		/**
		 * Handler for the TransformTool.TARGET_CHANGED event. This
		 * has no default behavior and is to be overriden by subclasses
		 * if needed.
		 */
		protected function targetChanged(event:Event):void {
			// to be overridden
		}
		
		/**
		 * Draws the visuals of the control. This is called when first
		 * added to the stage as a child of a TransformTool instance and
		 * when a child is added to the control's own display list.
		 * It can be called at any time to redraw the graphics of the
		 * control.
		 */
		public function draw():void {
			// to be overridden
		}
		
		/**
		 * Handler for the TransformTool.REDRAW event. This
		 * has no default behavior and is to be overriden by subclasses
		 * if needed.
		 */
		public function redraw(event:Event):void {
			// to be overridden
		}
	}
}