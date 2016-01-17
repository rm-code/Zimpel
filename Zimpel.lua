local Zimpel = {
    _VERSION     = '1.0.0',
    _DESCRIPTION = 'A small module able to encode and decode files based on the classic LZ78 algorithm.',
    _URL         = 'https://github.com/rm-code/',
    _LICENSE = [[
    Copyright (c) 2016 Robert Machmer
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
};

-- ------------------------------------------------
-- Constants
-- ------------------------------------------------

local MAX_DICTIONARY_SIZE = 9998;
local ENCODING_PATTERN = '%4d%s';
local DECODING_MATCH_PATTERN  = '[%w%s][%w%s][%w%s][%w%s].';
local DECODING_SPLIT_PATTERN = '([%w%s][%w%s][%w%s][%w%s])(.)';

-- ------------------------------------------------
-- Private Functions
-- ------------------------------------------------

---
-- Adds a character to the dictionary.
-- @param dictionary (table)  The dictionary to edit.
-- @param char       (string) The character to add.
--
local function addChar( dictionary, char )
    assert( #dictionary < MAX_DICTIONARY_SIZE, "Max dictionary size reached." );
    dictionary[#dictionary + 1] = char;
end

---
-- Gets a character from the dictionary.
-- @param dictionary (table)  The dictionary to get the character from.
-- @param index      (number) The index of the character to retrieve.
-- @return           (string) The character found in the table.
--
local function getChar( dictionary, index )
    return dictionary[index];
end

---
-- Looks up a character in the dictionary.
-- @param dictionary (table)  The dictionary to search through.
-- @param char       (string) The character to search for.
-- @return           (number) The index of the character or 0 if the character
--                             could not be found.
--
local function lookUp( dictionary, char )
    -- Search through the dictionary and return the character's index if it
    -- can be found.
    for i = 0, #dictionary do
        if char == dictionary[i] then
            return i;
        end
    end

    -- Add the character to the dictionary.
    addChar( dictionary, char );
    return 0;
end

---
-- Write a lua table as a string file.
-- @param ptable (table)  The table to process.
-- @return       (string) The contents of the table written as a string.
--
local function convertTableToString( ptable )
    assert( type( ptable ) == 'table', "Not a lua table!" );

    local output = "{";
    local function toString( value )
        if type( value ) == 'table' then
            for k, v in pairs( value ) do
                if type( v ) == 'table' then
                    output = output .. '[\'' .. tostring( k ) .. '\']={';
                    toString( v );
                    output = output .. '},';
                elseif type( k ) == 'number' then
                    output = output .. string.format( "[%i]='%s',", k, v );
                else
                    output = output .. string.format( "%s='%s',", k, v );
                end
            end
        end
    end
    toString( ptable );
    output = output .. "}";

    return output;
end

-- ------------------------------------------------
-- Public Functions
-- ------------------------------------------------

---
-- Encodes a string.
-- @param  rawString (string) The string to encode.
-- @return           (string) The created code.
--
function Zimpel.encode( rawString )
    local dictionary = { [0] = "" };
    local code = "";

    local prefix = "";
    for nextChar in rawString:gmatch('.') do
        local index = lookUp( dictionary, prefix .. nextChar );
        if index == 0 then
            local prefixIndex = lookUp( dictionary, prefix );
            code = code .. string.format( ENCODING_PATTERN, prefixIndex, nextChar );
            prefix = "";
        else
            prefix = prefix .. nextChar;
        end
    end

    -- Push any remaining character on the code.
    if prefix ~= "" then
        code = code .. string.format( ENCODING_PATTERN, 9999, prefix );
    end

    return code;
end

---
-- Encodes a lua table.
-- @param ptable (table)  The table to convert.
-- @return       (string) The created code.
--
function Zimpel.encodeTable( ptable )
    local str = convertTableToString( ptable );
    return Zimpel.encode( str );
end

---
-- Decodes a string.
-- @param  codedString (string) The string to decode.
-- @return             (string) The decoded message.
--
function Zimpel.decode( codedString )
    local dictionary = { [0] = "" };
    local message = "";

    local postfix = false;

    for code in codedString:gmatch( DECODING_MATCH_PATTERN ) do
        local prefixIndex, nextChar = code:match( DECODING_SPLIT_PATTERN );
        local prefix = getChar( dictionary, tonumber( prefixIndex ));

        -- Last entry reached.
        if tonumber( prefixIndex ) == MAX_DICTIONARY_SIZE + 1 then
            postfix = true;
            break;
        end

        if lookUp( dictionary, prefix .. nextChar ) == 0 then
            message = message .. prefix .. nextChar;
        end
    end

    -- Push remaining char on the message. This happens when the code ends with
    -- a character already contained in the dictionary.
    if postfix then
        local lastChar = codedString:match( "9999(.+)$" );
        message = message .. lastChar;
    end

    return message;
end

---
-- Decode lua table.
-- @param  codedString (string) The string to decode.
-- @return             (table)  The decoded table.
--
function Zimpel.decodeTable( codedString )
    local decodedString = Zimpel.decode( codedString );
    return loadstring("return " ..  decodedString)();
end

return Zimpel;
