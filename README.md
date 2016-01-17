# Zimpel
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/rm-code/Graphoon/releases/latest)
[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE.md)

A small module able to encode and decode files based on the classic LZ78 algorithm.

## Instructions

Zimpel can encode and decode strings:

```lua
local Zimpel = require('Zimpel')

local code = Zimpel.encode( "I have come here to chew bubblegum and kick ass...and I'm all out of bubblegum." )
print( code )

local msg = Zimpel.decode( code );
print( msg )
```

There are also functions for encoding and decoding tables:

```lua
local Zimpel = require('Zimpel')

local example = {
    bubblegum = false,
    kickass = true,
    equipment = {
        "sunglasses",
        "shotgun"
    }
}

local code = Zimpel.encodeTable( example )
print( code )

local dtable = Zimpel.decodeTable( code );
for i, v in pairs( dtable ) do
    print( i, v )
end
```
