package ru.kutu.grindplayer.views.mediators {
	
	import spark.effects.Fade;
	import flash.events.FullScreenEvent;
	
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.media.MediaPlayerState;
	
	import robotlegs.bender.extensions.contextView.ContextView;
	import robotlegs.bender.framework.api.IInjector;
	
	import ru.kutu.grind.config.PlayerConfiguration;
	import ru.kutu.grind.events.AutoHideEvent;
	
	import ru.kutu.grind.views.mediators.MediaControlBaseMediator;
	
	import ru.kutu.grindplayer.views.components.Logo;
	
	public class MyLogoMediator extends MediaControlBaseMediator {
		
		private static var LOGO_FADE_DURATION:uint = 600;
		
		[Inject] public var logo:Logo;
		[Inject] public var injector:IInjector;
		[Inject] public var contextView:ContextView;
		
		protected var autoHide:Boolean;
		protected var fullScreenAutoHide:Boolean;
		protected var isFullScreen:Boolean;
		
		private var fade:Fade;
		
		public function get shown():Boolean {
			return (fade.alphaTo == 1);
		}
		
		public function set shown(value:Boolean):void {
			
			if (value) {
				fade.alphaFrom = 0;
				fade.alphaTo = 1;
			} else {
				fade.alphaFrom = 1;
				fade.alphaTo = 0;
			}

			fade.stop();
			fade.play();
		}
		
		override public function initialize():void {
			super.initialize();
			
			fade = new Fade();
			fade.target = logo;
			fade.duration = LOGO_FADE_DURATION;
			
			var configuration:PlayerConfiguration = injector.getInstance(PlayerConfiguration);
			autoHide = configuration.controlBarAutoHide;
			fullScreenAutoHide = configuration.controlBarFullScreenAutoHide;
			if (autoHide || fullScreenAutoHide) {
				if (autoHide != fullScreenAutoHide) {
					contextView.view.stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
				}
				addContextListener(AutoHideEvent.SHOW, onAutoShow, AutoHideEvent);
				addContextListener(AutoHideEvent.HIDE, onAutoHide, AutoHideEvent);
				dispatch(new AutoHideEvent(AutoHideEvent.REPEAT_PLEASE));
			} else {
				shown = true;
			}
			player.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onMediaPlayerStateChange);
		}
		
		protected function onMediaPlayerStateChange(event:MediaPlayerStateChangeEvent = null):void {
			switch (player.state) {
				case MediaPlayerState.PLAYING:
				case MediaPlayerState.READY:
					//view.enabled = true;
					player.removeEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onMediaPlayerStateChange);
					break;
			}
		}
		
		protected function onFullScreen(event:FullScreenEvent):void {
			isFullScreen = event.fullScreen;
			if (isFullScreen) {
				if (!fullScreenAutoHide && !shown) {
					shown = true;
				}
			} else {
				if (!autoHide && !shown) {
					shown = true;
				}
			}
		}

		protected function onAutoShow(event:AutoHideEvent):void {
			shown = true;
		}

		protected function onAutoHide(event:AutoHideEvent):void {
			if (
				(isFullScreen && fullScreenAutoHide)
				||
				(!isFullScreen && autoHide)
			) {
				shown = false;
			}
		}
	}
	
}
