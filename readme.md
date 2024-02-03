# ZEngine

A basic game engine written in Zig.

## Features (initial alpha version to release before Feb. 28)
- ECS using zig-ecs
- Separated state and behavior
    - Components define state, Systems define behavior
- built-in systems
    - rendering using Kinc.zis
    - physics based on Box2D
- multiple entity registries per application

## TODO:
- built-in serialization
    - automatic and explicit version forwarding
    - components can be excluded from serialization
- All built-in systems are optional and modular.
    - set up a module system
    - will require refactoring the rendering and physics systems into separate modules

## Development steps
- create the framework of ZEngine
    - ECS
    - Make sure that entity registries can be instantiated in a non-static manner
        - Systems can either have a separate state for each registry, or a single state for all registries.

