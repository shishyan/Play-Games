--!nonstrict
-- Tiny service registry so server modules can call each other without circular requires.
-- init.server.luau fills it in; look services up at call time (Services.Enemy.foo()), never at require time.
local Services: { [string]: any } = {}
return Services
