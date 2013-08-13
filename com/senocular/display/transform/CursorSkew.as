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
	
	import flash.events.Event;
	import flash.geom.Point;
	
	/**
	 * Cursor for skew controls.
	 * @author Trevor McCauley
	 */
	public class CursorSkew extends Cursor {
		
		/**
		 * Skew mode used by the skew control this cursor is associated with.
		 * The skew mode is used to determine cursor rotation. This can be 
		 * either ControlUVSkewBar.X_AXIS or ControlUVSkewBar.Y_AXIS.
		 */
		public function get mode():String {
			return _mode;
		}
		public function set mode(value:String):void {
			_mode = value;
		}
		private var _mode:String;
		
		/**
		 * Constructor for creating new CursorSkew instances.
		 * @param	mode Skew mode used by the skew control this cursor is associated with.
		 */
		public function CursorSkew(mode:String = "xAxis") {
			super();
			this.mode = mode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function draw():void {
			super.draw();
			graphics.clear();
			
			// don't draw anything if something
			// has been added as a child to
			// this display object as a "skin"
			if (numChildren) return;
			
			with (graphics){
				//right arrow
				beginFill(this.fillColor, this.fillAlpha);
				lineStyle(this.lineThickness, this.lineColor, this.lineAlpha);
				moveTo(-6, -1);
				lineTo(6, -1);
				lineTo(6, -4);
				lineTo(10, 1);
				lineTo(-6, 1);
				lineTo(-6, -1);
				endFill();
				// left arrow
				beginFill(this.fillColor, this.fillAlpha);
				lineStyle(this.lineThickness, this.lineColor, this.lineAlpha);
				moveTo(10, 5);
				lineTo(-2, 5);
				lineTo(-2, 8);
				lineTo(-6, 3);
				lineTo(10, 3);
				lineTo(10, 5);
				endFill();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function redraw(event:Event):void {
			super.redraw(event);
			
			if (tool == null){
				return;
			}
			
			var vector:Point;
			switch(mode){
				
				case ControlUVSkewBar.Y_AXIS:{
					vector = new Point(0, 1);
					break;
				}
				
				case ControlUVSkewBar.X_AXIS:
				default:{
					vector = new Point(1, 0);
					break;
				}
			}
			
			vector = tool.calculatedMatrix.deltaTransformPoint(vector);
			rotation = Math.atan2(vector.y, vector.x) * (180/Math.PI);
		}
	}
}