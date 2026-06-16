# triangle

A colored triangle rendered with Metal on macOS.

![triangle](triangle.gif)

## Stack

- Objective-C + Cocoa (`main.m`)
- Metal + MetalKit
- Metal shaders (`shader.metal`) — interpolated per-vertex color

## Build

```bash
make
```

## Run

```bash
./triangle
```

## Clean

```bash
make clean
```

## Requirements

- macOS with Metal support
- Xcode command line tools (`clang`)
