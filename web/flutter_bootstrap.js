{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine({
      // Tắt accessibility DOM để giảm overhead
      nativeSpellCheck: false,
    });
    await appRunner.runApp();
  }
});
