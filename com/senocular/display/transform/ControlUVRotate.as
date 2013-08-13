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
	
	/**
	 * Allows the user to rotate the target object.
	 * @author Trevor McCauley
	 */
	public class ControlUVRotate extends ControlUV {
		
		/**
		 * Constructor for creating new ControlUVRotate instances.
		 * @param	u The U value for positioning the control in the x axis.
		 * @param	v The V value for positioning the control in the y axis.
		 * @param	cursor The cursor to be used while interacting with the
		 * control instance. 
		 */
		public function ControlUVRotate(u:Number = 1, v:Number = 1, cursor:Cursor = null){
			super(u, v, cursor);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
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
				beginFill(this.fillColor, this.fillAlpha);
				lineStyle(this.lineThickness, this.lineColor, this.lineAlpha);
				drawCircle(0, 0, 4);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function activeMouseMove(event:MouseEvent):void {
			super.activeMouseMove(event);
			
			rotate();
			
			// negative scaling would normally
			// be disabled here, but this control
			// prevents scaling restrictions through
			// the restrict event
			calculateAndUpdate(false);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function restrict(event:Event):void {
			// prevent the default restrictions
			// allowing this control to handle
			// all restrictions
			event.preventDefault();
			
			if (activeMouseEvent.shiftKey){
				
				// snap to 45 degree angles
				var snap:Number = Math.PI/4;
				tool.setRotation( Math.round(tool.getRotation()/snap)*snap );
			}
			
			// standard rotation restrictions
			// but not scaling restrictions since
			// if negative scaling is false, scale
			// restricts can scale while rotating
			tool.restrictRotation();
		}
	}
}