use tauri::plugin::TauriPlugin;
use tauri::Runtime;

// NyxRinth ships with no ads. This plugin is kept as a no-op stub since
// main.rs registers it, but none of the frontend ad helpers (see
// apps/app-frontend/src/helpers/ads.js) invoke any commands, so no
// commands need to be registered here.
pub fn init<R: Runtime>() -> TauriPlugin<R> {
	tauri::plugin::Builder::<R>::new("ads").build()
}
