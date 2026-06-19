{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    
    // Remove the splash screen
    if (typeof removeSplashFromWeb === 'function') {
      removeSplashFromWeb();
    } else {
      document.getElementById("splash")?.remove();
      document.getElementById("splash-branding")?.remove();
      document.body.style.background = "transparent";
    }

    await appRunner.runApp();
  }
});
