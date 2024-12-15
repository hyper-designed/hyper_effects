{{flutter_js}}
{{flutter_build_config}}

// Customize the app initialization process
_flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine({
            useColorEmoji: true
        });

        await appRunner.runApp();
    }

});
