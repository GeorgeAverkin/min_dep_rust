#![no_main]
#![no_core]
#![feature(no_core, lang_items, rustc_attrs, decl_macro)]

#[rustc_builtin_macro]
macro asm("assembly template", $(operands,)* $(options($(option),*))?) {
    /* compiler built-in */
}

#[lang = "panic_info"]
struct PanicInfo;

#[panic_handler]
fn my_panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[lang = "sized"]
trait Sized {}

#[lang = "copy"]
trait Copy {}

impl Copy for usize {}
impl Copy for *const () {}

#[repr(C)]
struct timespec {
    pub tv_sec: i64,
    pub tv_nsec: i64,
}

fn write() {
    const HELLO: &'static str = "Hello, world!\n\0";

    unsafe {
        asm!(
            "syscall",
            in("rax") 1usize, // syscall number
            in("rdi") 1usize, // fd
            in("rsi") HELLO as *const str as *const (),
            in("rdx") 15usize,
            out("rcx") _, // clobbered by syscalls
            out("r11") _, // clobbered by syscalls
        );
    }
}

fn nanosleep() {
    let time = timespec { tv_sec: 3, tv_nsec: 0 };

    unsafe {
        asm!(
            "syscall",
            in("rax") 35usize,                                // syscall number
            in("rdi") &time as *const timespec as *const (),  // res
            in("rsi") 0usize,                                 // rem
        );
    }
}

fn exit(code: usize) {
    let time = timespec { tv_sec: 3, tv_nsec: 0 };

    unsafe {
        asm!(
            "syscall",
            in("rax") 60usize, // syscall number
            in("rdi") code,  // exit code
        );
    }
}


#[cfg(feature = "static")]
#[no_mangle]
fn _start() {
    write();
    // loop {
    //     nanosleep();
    // }
    exit(0);
}

#[cfg(not(feature = "static"))]
#[no_mangle]
fn main(_argc: isize, _argv: *const *const u8) -> isize {
    write();
    loop {
        nanosleep();
    }
    0
}
