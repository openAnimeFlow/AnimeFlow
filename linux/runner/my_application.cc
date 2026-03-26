#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdint>
#include <cstring>
#include <utility>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

namespace {
// Native side state for rate calculation.
static bool has_last = false;
static uint64_t last_rx_bytes = 0;
static uint64_t last_tx_bytes = 0;
static double last_time_sec = 0.0;
static FlMethodChannel* method_channel = nullptr;

static double NowSeconds() {
  // Glib monotonic time in microseconds.
  return static_cast<double>(g_get_monotonic_time()) / 1000000.0;
}

static std::pair<uint64_t, uint64_t> ReadCurrentRxTxBytes() {
  uint64_t rx = 0;
  uint64_t tx = 0;

  std::ifstream file("/proc/net/dev");
  if (!file.is_open()) {
    return {0, 0};
  }

  std::string line;
  int line_no = 0;
  while (std::getline(file, line)) {
    // Skip header lines (first two lines)
    if (line_no < 2) {
      line_no++;
      continue;
    }
    line_no++;

    auto pos = line.find(':');
    if (pos == std::string::npos) {
      continue;
    }
    std::string iface = line.substr(0, pos);
    // trim spaces
    while (!iface.empty() && iface.front() == ' ') iface.erase(iface.begin());
    while (!iface.empty() && iface.back() == ' ') iface.pop_back();

    // Skip loopback
    if (iface == "lo" || iface == "lo0") {
      continue;
    }

    std::string rest = line.substr(pos + 1);
    std::istringstream iss(rest);

    // We only need rx_bytes and tx_bytes but read through to keep parsing aligned.
    uint64_t rx_bytes = 0;
    uint64_t rx_packets = 0;
    uint64_t rx_errs = 0;
    uint64_t rx_drop = 0;
    uint64_t rx_fifo = 0;
    uint64_t rx_frame = 0;
    uint64_t rx_compressed = 0;
    uint64_t rx_multicast = 0;
    uint64_t tx_bytes = 0;
    uint64_t tx_packets = 0;
    uint64_t tx_errs = 0;
    uint64_t tx_drop = 0;
    uint64_t tx_fifo = 0;
    uint64_t tx_frame = 0;
    uint64_t tx_compressed = 0;
    uint64_t tx_multicast = 0;

    if (!(iss >> rx_bytes >> rx_packets >> rx_errs >> rx_drop >> rx_fifo >> rx_frame >>
          rx_compressed >> rx_multicast >> tx_bytes >> tx_packets >> tx_errs >>
          tx_drop >> tx_fifo >> tx_frame >> tx_compressed >> tx_multicast)) {
      continue;
    }

    rx += rx_bytes;
    tx += tx_bytes;
  }

  return {rx, tx};
}

static void MethodCallCb(FlMethodChannel* channel,
                          FlMethodCall* method_call,
                          gpointer user_data) {
  (void)channel;
  (void)user_data;

  const gchar* method = fl_method_call_get_name(method_call);
  GError* error = nullptr;

  if (strcmp(method, "start") == 0) {
    has_last = true;
    auto now = NowSeconds();
    auto bytes = ReadCurrentRxTxBytes();
    last_time_sec = now;
    last_rx_bytes = bytes.first;
    last_tx_bytes = bytes.second;
    fl_method_call_respond_success(method_call, fl_value_new_null(), &error);
    return;
  }

  if (strcmp(method, "stop") == 0) {
    has_last = false;
    last_rx_bytes = 0;
    last_tx_bytes = 0;
    last_time_sec = 0.0;
    fl_method_call_respond_success(method_call, fl_value_new_null(), &error);
    return;
  }

  if (strcmp(method, "get") == 0) {
    auto bytesNow = ReadCurrentRxTxBytes();
    auto now = NowSeconds();

    if (!has_last || now <= last_time_sec) {
      has_last = true;
      last_time_sec = now;
      last_rx_bytes = bytesNow.first;
      last_tx_bytes = bytesNow.second;

      FlValue* map = fl_value_new_map();
      fl_value_set_string_take(map, "download", fl_value_new_int(0));
      fl_value_set_string_take(map, "upload", fl_value_new_int(0));
      fl_method_call_respond_success(method_call, map, &error);
      return;
    }

    const double dt = now - last_time_sec;
    const uint64_t rxDelta =
        (bytesNow.first >= last_rx_bytes) ? (bytesNow.first - last_rx_bytes) : 0;
    const uint64_t txDelta =
        (bytesNow.second >= last_tx_bytes) ? (bytesNow.second - last_tx_bytes) : 0;

    const int64_t downBps = static_cast<int64_t>(rxDelta / dt);
    const int64_t upBps = static_cast<int64_t>(txDelta / dt);

    // Update baselines.
    last_time_sec = now;
    last_rx_bytes = bytesNow.first;
    last_tx_bytes = bytesNow.second;

    FlValue* map = fl_value_new_map();
    fl_value_set_string_take(map, "download", fl_value_new_int(downBps));
    fl_value_set_string_take(map, "upload", fl_value_new_int(upBps));
    fl_method_call_respond_success(method_call, map, &error);
    return;
  }

  fl_method_call_respond_not_implemented(method_call, &error);
}
}  // namespace

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "AnimeFlow");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "AnimeFlow");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Register native MethodChannel: network_speed_monitor (start/get/stop)
  if (method_channel == nullptr) {
    FlBinaryMessenger* messenger =
        fl_engine_get_binary_messenger(fl_view_get_engine(view));
    FlStandardMethodCodec* codec = fl_standard_method_codec_new();
    method_channel = fl_method_channel_new(
        messenger, "network_speed_monitor", FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(
        method_channel, MethodCallCb, nullptr, nullptr);
  }

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
