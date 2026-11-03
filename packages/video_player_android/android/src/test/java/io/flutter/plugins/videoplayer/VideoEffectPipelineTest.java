package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import android.view.Surface;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.util.Size;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.PlayerMessage;
import androidx.media3.exoplayer.Renderer;
import androidx.media3.exoplayer.analytics.AnalyticsListener;
import io.flutter.plugins.videoplayer.texture.TextureVideoPlayer;
import io.flutter.view.TextureRegistry.SurfaceProducer;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InOrder;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class VideoEffectPipelineTest {
  private ExoPlayer player;
  private SurfaceProducer surface;
  private PlayerMessage message;

  @Before
  public void setUp() {
    player = mock(ExoPlayer.class);
    surface = mock(SurfaceProducer.class);
    when(surface.getSurface()).thenReturn(mock(Surface.class));
    Renderer renderer = mock(Renderer.class);
    when(player.getRendererCount()).thenReturn(1);
    when(player.getRendererType(0)).thenReturn(C.TRACK_TYPE_VIDEO);
    when(player.getRenderer(0)).thenReturn(renderer);
    message = mock(PlayerMessage.class, RETURNS_SELF);
    when(player.createMessage(renderer)).thenReturn(message);
  }

  private void inputSize(VideoEffectPipeline pipeline, int width, int height, int rotation) {
    pipeline.onVideoInputFormatChanged(
        mock(AnalyticsListener.EventTime.class),
        new Format.Builder().setWidth(width).setHeight(height).setRotationDegrees(rotation).build(),
        null);
  }

  @Test
  public void initialEffectIsSubmittedBeforePrepareAndNoneCanEnableLater() {
    VideoPlayerOptions options = new VideoPlayerOptions();
    options.videoEffect = PlatformVideoEffect.NONE;
    TextureVideoPlayer texture = new TextureVideoPlayer(
        mock(VideoPlayerCallbacks.class), surface, MediaItem.fromUri("https://example.com/v.mp4"),
        options, () -> player);
    InOrder order = inOrder(player);
    order.verify(player).setVideoEffects(argThat(List::isEmpty));
    order.verify(player).prepare();
    texture.setVideoEffect(PlatformVideoEffect.DEBUG_GRAYSCALE);
    verify(player).setVideoEffects(argThat(effects -> effects.size() == 1));
    texture.dispose();
    assertThrows(IllegalStateException.class, () -> texture.setVideoEffect(PlatformVideoEffect.NONE));
  }

  @Test
  public void synchronousEffectInitializationFailureReleasesThePlayer() {
    VideoPlayerOptions options = new VideoPlayerOptions();
    options.videoEffect = PlatformVideoEffect.DEBUG_GRAYSCALE;
    doThrow(new IllegalStateException("effect unavailable")).when(player).setVideoEffects(anyList());
    assertThrows(IllegalStateException.class, () -> new TextureVideoPlayer(
        mock(VideoPlayerCallbacks.class), surface, MediaItem.fromUri("https://example.com/v.mp4"),
        options, () -> player));
    verify(player).release();
    verify(player, never()).prepare();
  }

  @Test
  public void defaultPlaybackDoesNotCreateAnEffectsPipeline() {
    TextureVideoPlayer texture = new TextureVideoPlayer(
        mock(VideoPlayerCallbacks.class), surface, MediaItem.fromUri("https://example.com/v.mp4"),
        new VideoPlayerOptions(), () -> player);
    verify(player, never()).setVideoEffects(anyList());
    assertThrows(IllegalStateException.class,
        () -> texture.setVideoEffect(PlatformVideoEffect.DEBUG_GRAYSCALE));
    texture.dispose();
  }

  @Test
  public void inputMetadataUnblocksOutputAndSizeIsResentAfterChangingEffects() {
    VideoEffectPipeline pipeline = new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 1920, 1080, 0);
    verify(surface).setSize(1920, 1080);
    verify(message).setType(Renderer.MSG_SET_VIDEO_OUTPUT_RESOLUTION);
    verify(message).setPayload(new Size(1920, 1080));
    clearInvocations(message);
    pipeline.setEffect(PlatformVideoEffect.DEBUG_GRAYSCALE);
    verify(message).setPayload(new Size(1920, 1080));
    pipeline.dispose();
  }

  @Test
  public void surfaceRecreationUsesLatestRotatedInputSizeWithoutLosingEffect() {
    VideoEffectPipeline pipeline = new VideoEffectPipeline(player, surface, PlatformVideoEffect.DEBUG_GRAYSCALE);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 1920, 1080, 0);
    pipeline.onSurfaceCleanup();
    clearInvocations(player, surface, message);
    inputSize(pipeline, 1280, 720, 90);
    verifyNoInteractions(surface, message);
    pipeline.onSurfaceAvailable();
    InOrder order = inOrder(surface, player, message);
    order.verify(surface).setSize(720, 1280);
    order.verify(surface).getSurface();
    order.verify(player).setVideoSurface(any());
    order.verify(message).setPayload(new Size(720, 1280));
    verify(player, never()).setVideoEffects(anyList());
    pipeline.dispose();
    clearInvocations(surface, message);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 640, 360, 0);
    verifyNoInteractions(surface, message);
  }

  @Test
  public void configurationsAreIsolatedBetweenPlayers() {
    ExoPlayer secondPlayer = mock(ExoPlayer.class);
    VideoEffectPipeline first = new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    VideoEffectPipeline second = new VideoEffectPipeline(secondPlayer, mock(SurfaceProducer.class), PlatformVideoEffect.NONE);
    clearInvocations(secondPlayer);
    first.setEffect(PlatformVideoEffect.DEBUG_GRAYSCALE);
    verifyNoInteractions(secondPlayer);
    first.dispose();
    second.dispose();
  }
}
