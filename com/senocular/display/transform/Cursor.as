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
	 * Base class for Transform Tool cursors.  Cursors can be any DisplayObject
	 * instance. The Cursor class provides a styling properties and a basic 
	 * framework for updates and drawing.
	 * @author Trevor McCauley
	 */
	public class Cursor extends Sprite {
		
		/**
		 * The color to be used for filled shapes in dynamically drawn
		 * cursor graphics.
		 */
		public function get fillColor():uint { return _fillColor; }
		public function set fillColor(value:uint):void { _fillColor = value; }
		private var _fillColor:uint = 0x000000;
		
		/**
		 * The color to be used for outlines in dynamically drawn cursor
		 * graphics.
		 */
		public function get lineColor():uint { return _lineColor; }
		public function set lineColor(value:uint):void { _lineColor = value; }
		private var _lineColor:uint = 0xFFFFFF;
		
		/**
		 * The alpha of the color used for filled shapes in dynamically drawn
		 * cursor graphics.
		 */
		public function get fillAlpha():Number { return _fillAlpha; }
		public function set fillAlpha(value:Number):void { _fillAlpha = value; }
		private var _fillAlpha:Number = 1.0;
		
		/**
		 * The alpha of the color used for outlines in dynamically drawn 
		 * cursor graphics.
		 */
		public function get lineAlpha():Number { return _lineAlpha; }
		public function set lineAlpha(value:Number):void { _lineAlpha = value; }
		private var _lineAlpha:Number = 1.0;
		
		/**
		 * The thickness used for outlines in dynamically drawn cursor 
		 * graphics.
		 */
		public function get lineThickness():Number { return _lineThickness; }
		public function set lineThickness(value:Number):void { _lineThickness = value; }
		private var _lineThickness:Number = 0;
		
		/**
		 * A reference to the TransformTool instance used by the control
		 * containing the cursor. It is the responsibility of the control
		 * to provide a reference of the TransformTool to the cursor.
		 */
		public function get tool():TransformTool {
			return _tool;
		}
		public function set tool(value:TransformTool):void {
			if (value == _tool){
				return;
			}
			_tool = value;
		}
		private var _tool:TransformTool;
		
		/**
		 * Constructor for creating new Cursor instances.
		 */
		public function Cursor(){
			super();
			draw();
			addEventListener(Event.ADDED, added, true); // redraw when child assets added
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
		 * Draws the visuals of the cursor. This is called when an instance
		 * of Cursor is first created or when a child is added to its own
		 * display list. It can be called at any time to redraw the graphics 
		 * of the cursor.
		 */
		public function draw():void {
			// to be overridden
		}
		
		/**
		 * Handler for redrawing the cursor. Controls are responsible for
		 * calling this handler, typically from within their own 
		 * TransformTool.REDRAW handler.  Cursors do not listen for this
		 * event on their own.
		 */
		public function redraw(event:Event):void {
			// to be overridden
		}
	}
}