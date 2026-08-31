//! dlopen WallpaperKit (macos-wallpaper-daemon-rse).
//!
//! `wallpaperkit_apply_all_spaces` is Settings → Your Photos → Choose File…
//! then `WallpaperUserSettings.allDisplays` (Show on all Spaces).

use std::ffi::{CStr, CString, c_char, c_int};

type ApplyFn = unsafe extern "C" fn(*const c_char, *const c_char, c_int) -> c_int;
type ErrFn = unsafe extern "C" fn() -> *const c_char;

pub fn apply_all_spaces(image: &str, scale: &str, also_idle: bool) -> Result<(), String> {
    let lib_path = std::env::var("DENDRITIC_WALLPAPERKIT_LIB")
        .unwrap_or_else(|_| "libWallpaperKit.dylib".into());
    apply_with_lib(&lib_path, image, scale, also_idle)
}

fn apply_with_lib(lib_path: &str, image: &str, scale: &str, also_idle: bool) -> Result<(), String> {
    let path = CString::new(image).map_err(|_| "wallpaper path contains NUL".to_string())?;
    let scale_c = CString::new(scale).map_err(|_| "scale contains NUL".to_string())?;
    unsafe {
        let lib = libloading::Library::new(lib_path)
            .map_err(|e| format!("WallpaperKit dlopen {lib_path}: {e}"))?;
        let apply: libloading::Symbol<ApplyFn> = lib
            .get(b"wallpaperkit_apply_all_spaces\0")
            .map_err(|e| format!("wallpaperkit_apply_all_spaces: {e}"))?;
        let last_err: libloading::Symbol<ErrFn> = lib
            .get(b"wallpaperkit_last_error\0")
            .map_err(|e| format!("wallpaperkit_last_error: {e}"))?;
        let rc = apply(
            path.as_ptr(),
            scale_c.as_ptr(),
            if also_idle { 1 } else { 0 },
        );
        if rc == 0 {
            return Ok(());
        }
        let ptr = last_err();
        if ptr.is_null() {
            Err(format!("wallpaperkit_apply_all_spaces returned {rc}"))
        } else {
            Err(CStr::from_ptr(ptr).to_string_lossy().into_owned())
        }
    }
}
