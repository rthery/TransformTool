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
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * Allows the user to skew the target object.  Unlike other controls, a
	 * ControlUVSkewBar instance is hidden by default. Unlike other ControlUV
	 * instances, ControlUVSkewBar uses two UV coordinates for positioning, 
	 * drawing a "line" from each to represent the active area of the control.
	 * @author Trevor McCauley
	 */
	public class ControlUVSkewBar extends ControlUV {
		
		/**
		 * Skew mode for skewing on the x axis.
		 */
		public static const X_AXIS:String = "xAxis";
		
		/**
		 * Skew mode for skewing on the y axis.
		 */
		public static const Y_AXIS:String = "yAxis";
		
		/**
		 * A second U position to represent where the skew bar is drawn.
		 * ControlUVSkewBar instances are drawn between (u,v) and (u2,v2).
		 */
		public function get u2():Number {
			return _u2;
		}
		public function set u2(value:Number):void {
			_u2 = isNaN(value) ? 0 : value;
		}
		private var _u2:Number;
		
		/**
		 * A second V position to represent where the skew bar is drawn.
		 * ControlUVSkewBar instances are drawn between (u,v) and (u2,v2).
		 */
		public function get v2():Number {
			return _v2;
		}
		public function set v2(value:Number):void {
			_v2 = isNaN(value) ? 0 : value;
		}
		private var _v2:Number;
		
		/**
		 * Skew mode for skewing. This can be* either X_AXIS, or Y_AXIS.
		 */
		public function get mode():String {
			return _mode;
		}
		public function set mode(value:String):void {
			_mode = value;
		}
		private var _mode:String;
		
		/**
		 * The size of the control, or the thickness of the "line" drawn 
		 * between (u,v) and (u2,v2) that represents the active area of
		 * the control.
		 */
		public function get thickness():Number {
			return _thickness;
		}
		public function set thickness(value:Number):void {
			_thickness = value;
		}
		private var _thickness:Number = 4;
		
		/**
		 * Constructor for creating new ControlUVRotate instances.
		 * @param	u The U value for positioning one end of the control in the
		 * x axis.
		 * @param	v The V value for positioning one end of the control in the
		 * y axis.
		 * @param	u2 The U value for positioning the other end of the control
		 * in the x axis.
		 * @param	v2 The V value for positioning the other end of the control
		 * in the y axis.
		 * @param	mode The transform mode to use for skewing. This can be
		 * either X_AXIS, or Y_AXIS.
		 * @param	cursor The cursor to be used while interacting with the
		 * control instance. 
		 */
		public function ControlUVSkewBar(u:Number = 0, v:Number = 0, u2:Number = 1, v2:Number = 0, 
			mode:String = X_AXIS, cursor:Cursor = null) {
			
			super(u, v, cursor);
			this.u2 = u2;
			this.v2 = v2;
			this.mode = mode;
			fillAlpha = 0; // invisible
			lineThickness = NaN;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function draw():void {
			super.draw();
			redraw(null);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function redraw(event:Event):void {
			super.redraw(event);
			graphics.clear();
			
			// do not draw if no tool or no thickness
			if (tool == null || isNaN(_thickness)){
				return;
			}
			
			var toParent:Matrix = tool.calculatedMatrix.clone();
			toParent.invert();
			
			var start:Point = getUVPosition(u, v);
			var end:Point =  getUVPosition(_u2, _v2);
			
			var angle:Number = Math.atan2(end.y - start.y, end.x - start.x) - Math.PI/2;	
			var offset:Point = Point.polar(_thickness, angle);
			
			// draw bar
			with (graphics){
				beginFill(this.fillColor, this.fillAlpha);
				lineStyle(this.lineThickness, this.lineColor, this.lineAlpha);
				moveTo(start.x + offset.x, start.y + offset.y);
				lineTo(end.x + offset.x, end.y + offset.y);
				lineTo(end.x - offset.x, end.y - offset.y);
				lineTo(start.x - offset.x, start.y - offset.y);
				lineTo(start.x + offset.x, start.y + offset.y);
				endFill();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function setPosition():void {
			// overridden to prevent default ControlUV behavior
			// for these skew controls, drawing sets position
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function activeMouseMove(event:MouseEvent):void {
			super.activeMouseMove(event);
			
			switch(mode){
				
				case Y_AXIS:{
					skewYAxis();
					break;
				}
				
				case X_AXIS:
				default:{
					skewXAxis();
					break;
				}
			}
			
			calculateAndUpdate(false);
		}
	}
}