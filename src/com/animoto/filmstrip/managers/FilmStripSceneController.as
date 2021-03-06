package com.animoto.filmstrip.managers
{
	import com.animoto.filmstrip.FilmStrip;
	import com.animoto.filmstrip.FilmStripBlurMode;
	import com.animoto.filmstrip.FilmStripCaptureMode;
	import com.animoto.filmstrip.FilmStripEvent;
	import com.animoto.filmstrip.MotionBlurSettings;
	import com.animoto.filmstrip.PulseControl;
	import com.animoto.filmstrip.scenes.FilmStripScene;
	
	import flash.utils.Dictionary;
	
	/**
	 * Requests a list of visible children from the scene, then generates
	 * a MotionBlurController for each child object and sequences render.
	 * 
	 * @author moses gunesch
	 */
	public class FilmStripSceneController
	{
		public var filmStrip:FilmStrip;
		public var scene:FilmStripScene;
		public var currentTime:int;
		
		protected var renderCallback:Function;
		protected var motionBlurRetainer: Dictionary = new Dictionary(true);
		protected var deltas: Dictionary = new Dictionary(false);
		protected var motionBlurs: Array;
		protected var motionBlurIndex: int;
		protected var sceneBlur: MotionBlurController;
		protected var hasFilters: Boolean = false;
		
		public function FilmStripSceneController(scene: FilmStripScene)
		{
			this.scene = scene;
		}
		
		public function init(filmStrip:FilmStrip, renderCallback:Function):void {
			this.filmStrip = filmStrip;
			this.renderCallback = renderCallback;
			filmStrip.addEventListener(FilmStripEvent.RENDER_STOPPED, filmstripRenderStopped, false, 0, true);
			this.sceneBlur = newMotionBlur(scene, true);
			if (filmStrip.captureMode!=FilmStripCaptureMode.WHOLE_SCENE) {
				
			}
		}
		
		public function stopRendering():void {
			motionBlurs = null;
			for each (var blur:MotionBlurController in motionBlurRetainer) {
				blur.destroy();
			}
			sceneBlur.destroy();
			motionBlurRetainer = null;
			hasFilters = false;
		}
		
		public function destroy():void {
			stopRendering();
			filmStrip = null;
			renderCallback = null;
			scene = null;
		}
		
		public function renderFrame(currentTime:int):void {
			trace("renderFrame");
			this.currentTime = currentTime;
			
			// MotionBlurControllers are used for capture even when there are no subframes.
			if (filmStrip.captureMode==FilmStripCaptureMode.WHOLE_SCENE) {
				if (filmStrip.blurMode==FilmStripBlurMode.NONE) {
					singleCapture(0);
				}
				else if (MotionBlurSettings.useFixedFrameCount) {
					singleCapture(MotionBlurSettings.fixedFrameCount);
				}
				else {
					FilmStrip.error("You must set MotionBlurSettings.usefixedFrameCount to true for WHOLE_SCENE captureMode.");
				}
			}
			else {
				setupMultiCapture();
			}
		}
		
		protected function singleCapture(subframes:int):void {
			if (scene==null) {
				return; // render stopped
			}
			motionBlurs = [ sceneBlur ];
			sceneBlur.subframes = subframes;
			scene.redrawScene();
			sceneBlur.render();
		}
		
		protected function newMotionBlur(target:Object, wholeScene:Boolean):MotionBlurController {
			if (filmStrip.blurMode==FilmStripBlurMode.SPLIT_SUBFRAMES) {
				return new SplitBlurController(this, target, wholeScene);
			}
			return new MotionBlurController(this, target, wholeScene);
		}
		
		protected function setupMultiCapture():void {
			if (scene==null) {
				return; // render stopped
			}
			
			// In many cases this step is really only needed once, but it keeps us synced as objects enter and leave the scene.
			var children:Array = scene.getVisibleChildren();
			makeBlurControllers(children);
			
			if (motionBlurs.length == 0) {
				trace("scene empty in this frame.");
				complete();
				return;
			}
			if ( MotionBlurSettings.useFixedFrameCount == false ) {
				var totalSubframes:int = precalcSubframes(children);
				if (totalSubframes == 0 && hasFilters == false) {
					trace("Reverted to single capture - no blur in this frame.");
					singleCapture(0);
					return;
				}
			}
			else {
				for each (var blur:MotionBlurController in motionBlurs) {
					blur.subframes = MotionBlurSettings.fixedFrameCount;
				}
			}
			motionBlurIndex = -1;
			renderNextBlur();
		}
		
		protected function makeBlurControllers(children:Array):void {
			motionBlurs = new Array();
			var blur: MotionBlurController;
			hasFilters = false;
			
			for each (var child:Object in children) {
				if (child.visible && motionBlurRetainer[child]==null) {
					blur = newMotionBlur(child, false);
					motionBlurRetainer[child] = blur;
					motionBlurs.push(blur);
				}
				else {
					motionBlurs.push(motionBlurRetainer[child]);
				}
				if (!hasFilters && scene.getFilters(child)!=null) {
					hasFilters = true;
				}
			}
			
			// Clean up retainer
			for each (blur in motionBlurRetainer) {
				if (motionBlurs.indexOf(blur)==-1) {
					try {
						motionBlurRetainer[blur.target].destroy();
					} catch(e:Error){}
					delete motionBlurRetainer[blur.target];
				}
			}
		}
		
		protected function precalcSubframes(children:Array):int {
			var blur: MotionBlurController;
			var totalSubframes:int = 0;
			var frameRate:int = filmStrip.frameRate;
			
			// animate to previous or next frame time then back to currentTime to get deltas.
			// doing this centrally lets us check whether it's necessary to capture objects separately.
			if (!PulseControl.whitelistIsClear()) {
				PulseControl.whitelist(children);
			}
			PulseControl.setTime( Math.max(0, currentTime + (filmStrip.frameDuration * MotionBlurSettings.offset)) );
			for each (blur in motionBlurs) {
				blur.deltaMgr.recordStartValues();
			}
			PulseControl.setTime(currentTime);
			PulseControl.unwhitelist(children);
			var delta:Number;
			for each (blur in motionBlurs) {
				delta = blur.deltaMgr.getCompoundDelta();
				blur.subframes = MotionBlurSettings.getSubframeCount(frameRate, delta);
				totalSubframes += blur.subframes;
			}
			return totalSubframes;
		}
		
		public function subframeComplete(blur:MotionBlurController, index:int, done:Boolean):void {
			
			if (filmStrip.bitmapScene.contains(blur.container)==false) {
				filmStrip.bitmapScene.addChild(blur.container);
			}
			
			if (done) {
				renderNextBlur();
			}
		}
		
		protected function renderNextBlur():void {
			if (++motionBlurIndex >= motionBlurs.length) {
				complete();
			}
			else {
				var blur:MotionBlurController = (motionBlurs[motionBlurIndex] as MotionBlurController);
				if (blur.subframes>0) {
					trace("render "+ blur.subframes + " subframes for target '"+ blur.target.name+"'...");
				}
				blur.render();
				filmStrip.bitmapScene.addChild(blur.container);
			}
		}
		
		protected function complete():void {
			renderCallback();
		}
		
		protected function filmstripRenderStopped(event:FilmStripEvent):void {
			for each (var blur:MotionBlurController in motionBlurRetainer) {
				blur.destroy();
				delete motionBlurRetainer[blur.target];
			}
		}
	}
}