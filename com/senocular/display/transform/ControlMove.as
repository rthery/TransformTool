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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * Allows the user to move the target object by clicking and dragging on
	 * it. There are no graphics associated with ControlMove instances so no
	 * styling applies.  All interaction is handled through the target object
	 * of the TransformTool instance.
	 * @author Trevor McCauley
	 */
	public class ControlMove extends ControlInteractive {
		private static const AXIS_LOCK_TOLERANCE:uint = 40;
		
		/** 
		 * Target drag by mouse free to be done in any direction 
		 */
		public static const FREE:String = "free";
		
		/**
		 * Target drag by mouse on x axis only.
		 */
		public static const X_AXIS:String = "xAxis";
		
		/**
		 * Target drag by mouse on y axis only.
		 */
		public static const Y_AXIS:String = "yAxis";
		
		/**
		 * @inheritDoc
		 */
		override public function set tool(value:TransformTool):void {
			super.tool = value;
			
			var tool:TransformTool = super.tool;
			if (tool){
				this.target = tool.target;
			}else{
				this.target = null;
			}
		}
		
		/**
		 * Target display object to be transformed by the TransformTool.
		 * Control points may use the target to add listeners to, for example
		 * to move the target by dragging it.  This value is automatically
		 * updated through the TransformTool.TARGET_CHANGED event.
		 */
		public function get target():DisplayObject {
			return _target;
		}
		public function set target(value:DisplayObject):void {
			if (value == _target){
				return;
			}
			if (_target){
				_target.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				_target.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				_target.removeEventListener(MouseEvent.ROLL_OVER, rollOver);
				_target.removeEventListener(MouseEvent.ROLL_OUT, rollOut);
			}
			_target = value;
			if (_target){
				_target.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				_target.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
				_target.addEventListener(MouseEvent.ROLL_OVER, rollOver);
				_target.addEventListener(MouseEvent.ROLL_OUT, rollOut);
				
				var targetEvent:MouseEvent = tool.targetEvent as MouseEvent;
				if (targetEvent && targetEvent.type == MouseEvent.MOUSE_DOWN){
					rollOver(targetEvent);
					mouseDown(targetEvent);
				}
			}
		}
		private var _target:DisplayObject;
		
		/**
		 * Move mode for dragging. This can be either X_AXIS, Y_AXIS or FREE.
		 */
		public function get mode():String {
			return _mode;
		}
		private var _mode:String;
		
		private var _mouseStartLocation:Point = new Point();
		private var _targetStartLocation:Point = new Point();
		private var _shiftKeyPressed:Boolean = false;
		private var _needToGetStartLocation:Boolean = false;
		
		/**
		 * Constructor for creating new ControlMove instances.
		 * @param	cursor The cursor to be used while interacting with the
		 * control instance. For ControlMove instances, this cursor is
		 * displayed when interacting with the Transform Tool's target
		 * object.
		 */
		public function ControlMove(cursor:Cursor = null){
			super(cursor);
			
			_mode = FREE;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function targetChanged(event:Event):void {
			super.targetChanged(event);
			this.target = tool.target;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function activeMouseUp(event:MouseEvent):void {
			super.activeMouseUp(event);
			
			_shiftKeyPressed = false;
			_mouseStartLocation.x = 0;
			_mouseStartLocation.y = 0;
			_mode = FREE;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function activeMouseMove(event:MouseEvent):void {
			super.activeMouseMove(event);
			
			//If we release the shift key, then we stop locking the mouse move on one axis
			if (_shiftKeyPressed && !event.shiftKey)
			{
				_needToGetStartLocation = false;
				_shiftKeyPressed = false;
				_mouseStartLocation.x = 0;
				_mouseStartLocation.y = 0;
				_mode = FREE;
			}
			
			if (_needToGetStartLocation)
			{
				_targetStartLocation.x = mouse.x + offsetMouse.x - baseRegistration.x - event.localX;
				_targetStartLocation.y = mouse.y + offsetMouse.y - baseRegistration.y - event.localY;
				
				_needToGetStartLocation = false;
			}
			
			switch(_mode){
				case X_AXIS:{
					moveXAxis(_targetStartLocation.y);
					break;
				}
					
				case Y_AXIS:{
					moveYAxis(_targetStartLocation.x);
					break;
				}
					
				case FREE:
				default:{
					//Check if we are trying to move on one axis only
					if (event.shiftKey)
					{
						if (_mouseStartLocation.x == 0 && _mouseStartLocation.y == 0)
						{
							_shiftKeyPressed = true;
							_needToGetStartLocation = true;
							_mouseStartLocation.x = event.stageX;
							_mouseStartLocation.y = event.stageY;
						}	
						
						if (Math.abs(_mouseStartLocation.y - event.stageY) > AXIS_LOCK_TOLERANCE)
							_mode = Y_AXIS
						if (Math.abs(_mouseStartLocation.x - event.stageX) > AXIS_LOCK_TOLERANCE)
							_mode = X_AXIS;
					}
					
					move();
				}
			}
			
			calculateAndUpdate(false);
		}
	}
}