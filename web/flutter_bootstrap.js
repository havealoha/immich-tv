{{flutter_js}}
{{flutter_build_config}}

const bootShell = document.getElementById('boot-shell');
const bootStatus = document.getElementById('boot-status');

function setBootStatus(message) {
  if (bootStatus) {
    bootStatus.textContent = message;
  }
}

_flutter.loader
  .load({
    config: {
      canvasKitBaseUrl: 'canvaskit/',
      useLocalCanvasKit: true,
    },
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
    onEntrypointLoaded: async function (engineInitializer) {
      setBootStatus('Starting Immich TV…');
      const appRunner = await engineInitializer.initializeEngine();
      setBootStatus('Rendering…');
      await appRunner.runApp();
      if (bootShell) {
        window.setTimeout(() => bootShell.remove(), 0);
      }
    },
  })
  .catch((error) => {
    console.error('Flutter bootstrap failed.', error);
    setBootStatus(
      'The web app could not start on this device. Please reload and try again.'
    );
  });
