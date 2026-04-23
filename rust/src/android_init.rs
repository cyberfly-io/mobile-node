//! Android JNI bootstrap.
//!
//! Captures the JavaVM in `JNI_OnLoad` and exposes `nativeInitAndroidContext`
//! which Kotlin calls once with the app Context, so crates like
//! `ndk-context` / `hickory-resolver` / `rustls-platform-verifier` can resolve
//! the Android DNS + TLS roots from Rust.

use std::ffi::c_void;
use std::sync::OnceLock;

use jni::objects::{JClass, JObject};
use jni::sys::{jint, JNI_VERSION_1_6};
use jni::{JNIEnv, JavaVM};

static JAVA_VM: OnceLock<usize> = OnceLock::new();

/// Called by the Android linker when `System.loadLibrary` loads this .so.
#[no_mangle]
pub unsafe extern "system" fn JNI_OnLoad(vm: *mut jni::sys::JavaVM, _: *mut c_void) -> jint {
    let _ = JAVA_VM.set(vm as usize);
    JNI_VERSION_1_6
}

/// Called from Kotlin `CyberflyApplication` with the application Context.
/// Stashes a global ref to the Context and initializes `ndk_context`.
#[no_mangle]
pub unsafe extern "system" fn Java_io_cyberfly_cyberfly_1mobile_1node_CyberflyApplication_nativeInitAndroidContext(
    env: JNIEnv,
    _class: JClass,
    context: jni::sys::jobject,
) {
    let vm_ptr = match JAVA_VM.get() {
        Some(p) => *p as *mut c_void,
        None => {
            // Fall back: ask the JNIEnv for its VM.
            match env.get_java_vm() {
                Ok(vm) => vm.get_java_vm_pointer() as *mut c_void,
                Err(_) => return,
            }
        }
    };

    // Promote local ref to a long-lived global ref; leak it so the ptr stays valid.
    let global = match env.new_global_ref(JObject::from_raw(context)) {
        Ok(g) => g,
        Err(_) => return,
    };
    let ctx_ptr = global.as_obj().as_raw() as *mut c_void;
    std::mem::forget(global);

    ndk_context::initialize_android_context(vm_ptr, ctx_ptr);
}

// Silence unused-import warnings when building for other targets.
#[allow(dead_code)]
fn _assert_vm_type(_: JavaVM) {}
