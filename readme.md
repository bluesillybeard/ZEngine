# ZEngine

A basic game engine written in Zig.

## Important notice
ZEngine is early in development. It may *seem* like an insanely tiny library, therefore it's impossible to get wrong. However, since this is an isanely critical part of a game, despite its simplicity there still so much it can improve. As such, expect breaking changes!

## Features
- ECS using zig-ecs
- Separated state and behavior
    - Components define state, Systems define behavior
- multiple entity registries per application
    - This means, you can have multiple instances of your application, but still have a single rendering system.
- Fully modular - ZEngine is merely the framework for a more advanced custom solution to be built. Official modules are in separate repositories, so they are 100% optional.
    - This means you can use the official system, use someone elses, or just write your own!

## Official systems
- None at the moment - you'll have to do mostly everything yourself

## Examples
see [ZEngineExamples](https://github.com/bluesillybeard/ZEngineExamples) for examples on how to use ZEngine

## TODO:
- built-in serialization
    - automatic and explicit version forwarding
    - components can be excluded from serialization
