;
; This program is licensed under the MIT License
; Copyright (c) 2023 Spydr06
;

[bits 64]

%define SYS_write 1
%define SYS_exit  60
%define SYS_uname 63
%define SYS_sysinfo 99

%define stdout 1
%define info_callback_location 8

; uname output struct
%define utsname_length 65
%define utsname_size utsname_length * 6
%define utsname_release_offset utsname_length * 2

; sysinfo output struct
%define sysinfo_size 112
%define sysinfo_totalram_offset 32
%define sysinfo_freeram_offset 40
%define sysinfo_sharedram_offset 48
%define sysinfo_bufferram_offset 56

%define mb_size 1024 * 1024

section .text

; entry point
global _start
_start:

    mov rax, info_callbacks
    push rax

    ; push logo start to stack
    mov rax, logo
    push rax

.print_line:
    ; check if we reached the logo end
    pop rsi
    cmp rsi, logo_end
    jge .print_end

    ; get the current line
    mov rdi, rsi
    call strlen

    ; increase and store the logo ptr
    inc rcx
    mov rdx, rsi
    add rdx, rcx
    push rdx

    ; restore the line length
    dec rcx

    ; write(1, <logo line>, <line len>)
    mov rax, SYS_write
    mov rdi, stdout
    mov rdx, rcx
    syscall

    ; get info callback function
    mov rax, [rsp + info_callback_location]
    call [rax]
    ; increment to next callback function
    add QWORD [rsp + info_callback_location], 8

    ; finish the line
    call write_newln

    jmp .print_line

.print_end:

    ; _exit(0)
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

exit_err:
    mov rax, SYS_exit
    mov rdi, 1
    syscall

; char ptr in rsi
write_chr:
    ; write(1, <rsi>, 1)
    mov rax, SYS_write
    mov rdi, stdout
    mov rdx, 1
    syscall

    ret

write_newln:
    mov rsi, newln
    call write_chr

    ret

write_int:
    mov rcx, 10
    push rax
    push rdx
    xor rdx, rdx
    div rcx
    test rax, rax
    jz .print_char
    call write_int
.print_char:
    add rdx, '0'
    push rdx
    mov rsi, rsp
    call write_chr
    pop rdx

    pop rdx
    pop rax
    ret

; string in rdi, return rcx
strlen:
    mov rcx, -1
    xor rax, rax
    cld
    repne scasb
    xor rcx, -1
    dec rcx
    ret

fetch_ip:
    mov rsi, a
    call write_chr
    ret

fetch_wm:
    mov rsi, b
    call write_chr
    ret

fetch_cpu:
    mov rsi, c
    call write_chr
    ret

fetch_gpu:
    mov rsi, d
    call write_chr
    ret

fetch_ram:
    ; struct sysinfo
    sub rsp, sysinfo_size

    ; get system information
    mov rdi, rsp
    mov rax, SYS_sysinfo
    syscall

    ; print used ram
    mov rax, [rsp + sysinfo_totalram_offset]
    sub rax, [rsp + sysinfo_freeram_offset]
    sub rax, [rsp + sysinfo_sharedram_offset]
    sub rax, [rsp + sysinfo_bufferram_offset]
    xor rdx, rdx
    mov rcx, mb_size
    div rcx
    call write_int

    ; write(1, " Mb / ", 6)
    mov rax, SYS_write
    mov rdi, stdout
    mov rsi, ram_mid_text
    mov rdx, ram_mid_text_len
    syscall

    ; print free ram
    mov rax, [rsp + sysinfo_totalram_offset]
    xor rdx, rdx
    mov rcx, mb_size
    div rcx
    call write_int

    ; write(1, "Mb", 2)
    mov rax, SYS_write
    mov rdi, stdout
    mov rsi, ram_end_text
    mov rdx, ram_end_text_len
    syscall

    add rsp, sysinfo_size
    ret

fetch_shell:
    mov rsi, e
    call write_chr
    ret

fetch_krnl_version:
    ; struct utsname
    sub rsp, utsname_size

    ; get kernel version
    mov rdi, rsp
    mov rax, SYS_uname
    syscall

    mov rsi, rsp
    add rsi, utsname_release_offset

    ; write(1, <kernel release>, utsname_lenght)
    mov rax, SYS_write
    mov rdi, stdout
    mov rdx, utsname_length
    syscall

    ; restore stack
    add rsp, utsname_size
    ret

fetch_pkgs:
    mov rsi, h
    call write_chr
    ret

dummy:
    ret

section .rodata

%define bold 27, "[1m"
%define cyan 27, "[36m"
%define reset 27, "[0m"

const_10 db 0x0a

newln:
    db 0x0a

logo:
    db " ▄████▄                 ", bold, cyan, "ip",  reset, 9, 0
    db "███  ██▄                ", bold, cyan, "wm",  reset, 9, 0
    db "▀▀    ██▄               ", bold, cyan, "cpu", reset, 9, 0
    db "       ██               ", bold, cyan, "gpu", reset, 9, 0
    db "      ████              ", bold, cyan, "ram",  reset, 9, 0
    db "    ██████▄             ", bold, cyan, "sh", reset, 9, 0
    db "   ██▀  ███             ", bold, cyan, "knl", reset, 9, 0
    db " ▄██▀    ██▄▄██         ", bold, cyan, "pkg", reset, 9, 0
    db " ██▀      ▀██▀", 0
logo_end:

ram_mid_text db "Mb / "
ram_mid_text_len equ $ - ram_mid_text
    
ram_end_text db "Mb"
ram_end_text_len equ $ - ram_end_text

info_callbacks:
    dq fetch_ip
    dq fetch_wm
    dq fetch_cpu
    dq fetch_gpu
    dq fetch_ram
    dq fetch_shell
    dq fetch_krnl_version
    dq fetch_pkgs
    dq dummy
    dq dummy

a db "a", 0
b db "b", 0
c db "c", 0
d db "d", 0
e db "e", 0
h db "h", 0