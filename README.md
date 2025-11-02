# 2D ASM File System

A simple 2D file system simulator written in **x86-64 Assembly** for **Linux**.  
Created as a school project to practice low-level programming, memory management, and system calls.

## 🧩 Features
- 2D grid of cells acting as files or directories  
- Basic commands: `move`, `create`, `delete`, `read`, `write`, `exit`  
- Uses Linux syscalls (`read`, `write`, `open`, `close`)  
- Text-based user interface  

## ⚙️ Build & Run
```bash
as -o main2.o main2.s
gcc -nostartfiles -o fs2d main2.o
./fs2d
