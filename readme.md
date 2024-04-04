# ZEngine

A basic game engine written in Zig. It's more of a basic foundation than anything.

## Important notice
ZEngine is early in development. It may *seem* like an insanely tiny library, therefore it's impossible to get wrong. However, since this is a critical part of a game, despite its simplicity there is still so much it can improve. As such, expect breaking changes!

Also, ZEngine is specifically created for my own projects. It's MIT licensed for a reason - I have little care about what other people do with it, since I created it for my own use.

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
