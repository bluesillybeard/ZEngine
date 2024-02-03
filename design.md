# Design of ZRender

ZRender is based on systems and components. There are two categories of systems:
- Global systems
    - These are allocated once for the lifetime of the program
- Local systems
    - these are instantiated and deinitialized for every world that is created

Components are just regular structs that contain data.

Global systems are stored in a single registry that is initialized at the start of the application

Local systems are stored in one registry per world.

The registry contains every system, and systems cannot be added or removed at runtime.

A world is contains a two things:
- System registry
- ECS


