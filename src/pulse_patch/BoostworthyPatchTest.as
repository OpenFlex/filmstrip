package {
	import com.animoto.filmstrip.PulseControl;
	import com.boostworthy.animation.easing.Transitions;
	import com.boostworthy.animation.management.AnimationManager;
	import com.boostworthy.animation.rendering.RenderMethod;
	
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import gs.easing.Elastic;
	
	[SWF(backgroundColor="#FFFFFF", frameRate="30")]
	
	public class BoostworthyPatchTest extends Sprite
	{
		private var t:TextField;
		public function KitchenSyncPatchTest()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			t = new TextField();
			t.border = true;
			t.width = 200;
			t.height = 20;
			t.x = 100;
			t.y = 100;
			addChild(t);
			
			PulseControl.addEnterFrameListener(updateTime);
			
			var s:Sprite = new Sprite();
			s.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0x336699], [1,1], [0,255]);
			s.x = 100;
			s.y = 50;
			s.graphics.drawRect(-11, -11, 22, 22);
			addChild(s);
			var mgr:AnimationManager = new AnimationManager();
			mgr.move(s, 500, s.y, 6000, Transitions.ELASTIC_OUT);
			
			
			var b:TextField = new TextField();
			b.border = true;
			b.background = true;
			b.backgroundColor = 0xEEEEEE;
			b.selectable = false;
			b.text = "freeze";
			b.autoSize = "left";
			b.x = 100;
			b.y = 150;
			b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { 
				PulseControl.freeze(); 
			});
			addChild(b);
			
			b = new TextField();
			b.border = true;
			b.background = true;
			b.backgroundColor = 0xEEEEEE;
			b.selectable = false;
			b.text = "resume";
			b.autoSize = "left";
			b.x = 100;
			b.y = 180;
			b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { 
				PulseControl.resume(); 
			});
			addChild(b);
			
			b = new TextField();
			b.border = true;
			b.background = true;
			b.backgroundColor = 0xEEEEEE;
			b.selectable = false;
			b.text = "advance";
			b.autoSize = "left";
			b.x = 100;
			b.y = 210;
			b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { 
				PulseControl.advanceTime(1000/15); 
			});
			addChild(b);
			
			b = new TextField();
			b.border = true;
			b.background = true;
			b.backgroundColor = 0xEEEEEE;
			b.selectable = false;
			b.text = "add listener";
			b.autoSize = "left";
			b.x = 100;
			b.y = 240;
			b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { 
				PulseControl.addEnterFrameListener(updateTime); 
			});
			addChild(b);
			
			b = new TextField();
			b.border = true;
			b.background = true;
			b.backgroundColor = 0xEEEEEE;
			b.selectable = false;
			b.text = "remove listener";
			b.autoSize = "left";
			b.x = 100;
			b.y = 270;
			b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { 
				PulseControl.removeEnterFrameListener(updateTime); 
			});
			addChild(b);
		}
		
		private function updateTime(e:Event):void {
			t.text = String(PulseControl.getCurrentTime()); 
		}
		
	}
}
