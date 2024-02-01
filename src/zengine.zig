// This is the root module where public declarations are exposed.

pub const ZEngineComptimeOptions = struct {
    /// A global system has once instance for the lifetime of the application
    globalSystems: []const type,
    /// Local systems have one instance per entity registry
    localSystems: []const type,
};

/// ZEngine requires a bunch of compile-time information from the user. This function should only be called once for each application.
pub fn ZEngine(comptime options: ZEngineComptimeOptions) type {
    return struct{
        pub const Options = options;

    };
}
