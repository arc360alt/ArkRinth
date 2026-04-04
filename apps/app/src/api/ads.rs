use tauri::plugin::TauriPlugin;
use tauri::Runtime;

pub fn init<R: Runtime>() -> TauriPlugin<R> {
tauri::plugin::Builder::<R>::new("ads").build()
}
