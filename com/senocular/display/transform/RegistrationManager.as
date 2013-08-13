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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * Manages registration points used by TransformTool instances when
	 * working with target objects. Every TransformTool instance requires a
	 * RegistrationManager instance to manage registration points, though 
	 * multiple Transform Tools can use the same registration managers.  
	 * @author Trevor McCauley
	 */
	public class RegistrationManager {
		
		/**
		 * Determines whether or not registration points are saved for
		 * target object instances. When disabled (false) any saved
		 * registration points are removed through a clear() action.
		 * Default registration positions will still be respected when
		 * enabled is false.
		 */
		public function get enabled():Boolean {
			return _enabled;
		}
		public function set enabled(value:Boolean):void {
			_enabled = value;
			if (_enabled == false){
				clear();
			}
		}
		private var _enabled:Boolean = true;
		
		/**
		 * Default registration point location based on UV coordinates
		 * (percent relative to target). This position has precedence over
		 * defaultXY. If both are defined defaultUV will be used.
		 */
		public function get defaultUV():Point {
			return _defaultUV;
		}
		public function set defaultUV(value:Point):void {
			_defaultUV = value ? value.clone() : null;
		}
		private var _defaultUV:Point;
		
		/**
		 * Default registration point location based on
		 * x and y locations. If this is defined and defaultUV
		 * is not, this location will be used for the default
		 * registration point.
		 */
		public function get defaultXY():Point {
			return _defaultXY;
		}
		public function set defaultXY(value:Point):void {
			_defaultXY = value ? value.clone() : null;
		}
		private var _defaultXY:Point;
		
		/**
		 * Lookup for registration points. Each registration point is
		 * a Point object using the target object to which it is
		 * associated as the key.
		 */
		protected var map:Dictionary;
		
		/**
		 * Constructor for creating new RegistrationManager instances.
		 */
		public function RegistrationManager() {
			map = new Dictionary(true);
		}
		
		/**
		 * Clears registration points from the manager. If a target is 
		 * specified, only the registration point for that target object
		 * is cleared. Otherwise all registration points are cleared.
		 * @param	target A specific object in which a registration point
		 * should be cleared.
		 */
		public function clear(target:DisplayObject = null):void {
			if (target){
				delete map[target];
			}else{
				var key:Object;
				for (key in map){
					delete map[target];
				}
			}
		}
		
		/**
		 * Determines if a registration point exists for a target object.
		 * @param	target The target object to use to look up the existence
		 * of a registration point.
		 * @return True if a registration point has been saved for the target
		 * object, false if not.
		 */
		public function contains(target:DisplayObject):Boolean {
			return target in map;
		}
		
		/**
		 * Sets the registration point for an object.  This will only work
		 * if enabled is true.
		 * @param	target The target object for which to set a registration
		 * point.
		 * @param	point The point to define as the registration point for the
		 * target object. Registration points are defined in a target object's
		 * local coordinate space.
		 */
		public function setRegistration(target:DisplayObject, point:Point):void {
			if (_enabled && target && point){
				map[target] = point.clone();
			}
		}
		
		/**
		 * Returns the registration point associated with a target object.
		 * @param	target The object for which to find a registration point.
		 * @return The saved registration point for the target. If the target
		 * is null, or there is no defaults and a registration point has not
		 * been saved for the target, null is returned.  If no registration 
		 * point has been defined but defaults have been defined, a default
		 * is returned.  Otherwise the saved registration point for the
		 * target object is returned.
		 */
		public function getRegistration(target:DisplayObject):Point {
			// no target, no point
			if (target == null){
				return null;
			}
			
			// saved registration point
			var result:Point = map[target] as Point;
			if (result){
				return result;
			}
			
			// defaults
			if (_defaultUV){
				
				// get registration point based on
				// default location using UV coordinates
				var bounds:Rectangle = target.getBounds(target);
				return new Point(
					bounds.x + bounds.width * _defaultUV.x, 
					bounds.y + bounds.height * _defaultUV.y
				);
				
			}else if (_defaultXY){
				
				// get registration point from
				// default location
				return _defaultXY.clone();
			}
			
			// nothing available - no saved, no defaults
			return null;
		}
	}
}