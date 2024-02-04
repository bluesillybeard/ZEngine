# ZEngine

A basic game engine written in Zig.

## Features (initial alpha version to be ready before Feb. 28)
- ECS using zig-ecs
- Separated state and behavior
    - Components define state, Systems define behavior
- multiple entity registries per application
    - This means, you can have multiple instances of your application, but still have a single rendering system.
- Fully modular - ZEngine is merely the framework for a more advanced custom solution to be built. Official modules are in separate repositories, so they are 100% optional.
    - This means you can use the official rendering system, use someone elses, or just write your own!

## Official systems
- Rendering system based on Kinc (Not written yet)
    - Should be ready for alpha before Feb. 28
- Physics system based on Box2D v3 (Not written yet)
    - Should be ready for alpha before Feb. 28
- Audio system based on PortAudio (Not written yet)
    - Might be ready for alpha before Feb. 28
- UI system based on ImGui (Not written yet)
    - integrates with the official rendering system, although can be configured to use nearly any rendering system
    - Might be ready for alpha before Feb. 28


## TODO:
- built-in serialization
    - automatic and explicit version forwarding
    - components can be excluded from serialization
- increase test coverage
