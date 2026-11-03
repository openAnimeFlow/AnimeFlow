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
    TextureVideoPlayer texture =
        new TextureVideoPlayer(
            mock(VideoPlayerCallbacks.class),
            surface,
            MediaItem.fromUri("https://example.com/v.mp4"),
            options,
            () -> player);
    InOrder order = inOrder(player);
    order
        .verify(player)
        .setVideoEffects(
            argThat(
                effects ->
                    effects.size() == 1
                        && ((SwitchableVideoEffect) effects.get(0)).getEffect()
                            == PlatformVideoEffect.NONE));
    order.verify(player).prepare();
    texture.setVideoEffect(PlatformVideoEffect.DEBUG_GRAYSCALE);
    verify(player, times(1))
        .setVideoEffects(
            argThat(
                effects ->
                    effects.size() == 1
                        && ((SwitchableVideoEffect) effects.get(0)).getEffect()
                            == PlatformVideoEffect.DEBUG_GRAYSCALE));
    texture.dispose();
    assertThrows(
        IllegalStateException.class, () -> texture.setVideoEffect(PlatformVideoEffect.NONE));
  }

  @Test
  public void synchronousEffectInitializationFailureReleasesThePlayer() {
    VideoPlayerOptions options = new VideoPlayerOptions();
    options.videoEffect = PlatformVideoEffect.DEBUG_GRAYSCALE;
    doThrow(new IllegalStateException("effect unavailable"))
        .when(player)
        .setVideoEffects(anyList());
    assertThrows(
        IllegalStateException.class,
        () ->
            new TextureVideoPlayer(
                mock(VideoPlayerCallbacks.class),
                surface,
                MediaItem.fromUri("https://example.com/v.mp4"),
                options,
                () -> player));
    verify(player).release();
    verify(player, never()).prepare();
  }

  @Test
  public void defaultPlaybackDoesNotCreateAnEffectsPipeline() {
    TextureVideoPlayer texture =
        new TextureVideoPlayer(
            mock(VideoPlayerCallbacks.class),
            surface,
            MediaItem.fromUri("https://example.com/v.mp4"),
            new VideoPlayerOptions(),
            () -> player);
    verify(player, never()).setVideoEffects(anyList());
    assertThrows(
        IllegalStateException.class,
        () -> texture.setVideoEffect(PlatformVideoEffect.DEBUG_GRAYSCALE));
    texture.dispose();
  }

  @Test
  public void inputMetadataUnblocksOutputAndSameSizeEffectDoesNotRebindSurface() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 1920, 1080, 0);
    verify(surface).setSize(1920, 1080);
    verify(message).setType(Renderer.MSG_SET_VIDEO_OUTPUT_RESOLUTION);
    verify(message).setPayload(new Size(1920, 1080));
    clearInvocations(message, surface);
    pipeline.setEffect(PlatformVideoEffect.DEBUG_GRAYSCALE);
    verifyNoInteractions(message, surface);
    pipeline.dispose();
  }

  @Test
  public void surfaceRecreationUsesLatestRotatedInputSizeWithoutLosingEffect() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.DEBUG_GRAYSCALE);
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
  public void anime4kDoublesOutputAndOffRestoresOriginalSize() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 640, 360, 0);
    clearInvocations(surface, message, player);
    pipeline.setEffect(PlatformVideoEffect.ANIME4K_X2S);
    verify(player, never()).setVideoEffects(anyList());
    verify(surface).setSize(1280, 720);
    verify(message).setPayload(new Size(1280, 720));
    clearInvocations(surface, message);
    pipeline.setEffect(PlatformVideoEffect.NONE);
    verify(surface).setSize(640, 360);
    verify(message).setPayload(new Size(640, 360));
    pipeline.dispose();
  }

  @Test
  public void anime4kKeepsScaledRotatedSizeAcrossSurfaceRecreationAndFormatChanges() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.ANIME4K_X2S);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 640, 360, 90);
    verify(surface).setSize(720, 1280);
    pipeline.onSurfaceCleanup();
    clearInvocations(surface, message);
    inputSize(pipeline, 1280, 720, 90);
    verifyNoInteractions(surface, message);
    pipeline.onSurfaceAvailable();
    verify(surface).setSize(1440, 2560);
    verify(message).setPayload(new Size(1440, 2560));
    pipeline.dispose();
  }

  @Test
  public void repeatedAndRapidSelectionsNeverReregisterTheEffectChain() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 640, 360, 0);
    clearInvocations(player, surface, message);
    pipeline.setEffect(PlatformVideoEffect.NONE);
    verifyNoInteractions(player, surface, message);
    for (int i = 0; i < 40; i++) {
      pipeline.setEffect(i % 2 == 0 ? PlatformVideoEffect.ANIME4K_X2S : PlatformVideoEffect.NONE);
    }
    verify(player, never()).setVideoEffects(anyList());
    assertEquals(
        new Size(640, 360),
        pipeline.getOutputSize(new Format.Builder().setWidth(640).setHeight(360).build()));
    pipeline.dispose();
  }

  @Test
  public void hdrRejectsAnime4kWithoutChangingTheExistingPipeline() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    pipeline.onSurfaceAvailable();
    pipeline.onVideoInputFormatChanged(
        mock(AnalyticsListener.EventTime.class),
        new Format.Builder()
            .setWidth(1920)
            .setHeight(1080)
            .setColorInfo(
                new androidx.media3.common.ColorInfo.Builder()
                    .setColorSpace(C.COLOR_SPACE_BT2020)
                    .setColorTransfer(C.COLOR_TRANSFER_ST2084)
                    .setColorRange(C.COLOR_RANGE_LIMITED)
                    .build())
            .build(),
        null);
    clearInvocations(player, surface, message);
    assertThrows(
        IllegalArgumentException.class, () -> pipeline.setEffect(PlatformVideoEffect.ANIME4K_X2S));
    verifyNoInteractions(player, surface, message);
    pipeline.dispose();
  }

  @Test
  public void configurationsAreIsolatedBetweenPlayers() {
    ExoPlayer secondPlayer = mock(ExoPlayer.class);
    VideoEffectPipeline first = new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    VideoEffectPipeline second =
        new VideoEffectPipeline(
            secondPlayer, mock(SurfaceProducer.class), PlatformVideoEffect.NONE);
    clearInvocations(secondPlayer);
    first.setEffect(PlatformVideoEffect.DEBUG_GRAYSCALE);
    verifyNoInteractions(secondPlayer);
    first.dispose();
    second.dispose();
  }

  @Test
  public void efficiencyAndOffShareThePhysicalViewportWithoutReplacingSurface() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    pipeline.onSurfaceAvailable();
    inputSize(pipeline, 640, 360, 0);
    pipeline.setEffect(PlatformVideoEffect.NONE, 1080L, 608L);
    clearInvocations(player, surface, message);
    pipeline.setEffect(PlatformVideoEffect.ANIME4K_EFFICIENCY, 1080L, 608L);
    pipeline.setEffect(PlatformVideoEffect.NONE, 1080L, 608L);
    verifyNoInteractions(player, surface, message);
    pipeline.setEffect(PlatformVideoEffect.ANIME4K_EFFICIENCY, 1920L, 1080L);
    verify(surface).setSize(1920, 1080);
    verify(player, never()).setVideoEffects(anyList());
    pipeline.dispose();
  }

  @Test
  public void invalidOutputDimensionsAreRejectedBeforeChangingThePipeline() {
    VideoEffectPipeline pipeline =
        new VideoEffectPipeline(player, surface, PlatformVideoEffect.NONE);
    clearInvocations(player, surface, message);
    assertThrows(
        IllegalArgumentException.class,
        () -> pipeline.setEffect(PlatformVideoEffect.ANIME4K_EFFICIENCY, 100L, null));
    assertThrows(
        IllegalArgumentException.class,
        () -> pipeline.setEffect(PlatformVideoEffect.ANIME4K_EFFICIENCY, -1L, 100L));
    verifyNoInteractions(player, surface, message);
    pipeline.dispose();
  }
}
