grammar JSON;

// Parser rules
json: object
    | array
    ;

object: '{' pair (',' pair)* '}'  # AnObject
      | '{' '}'                    # EmptyObject
      ;


pair: STRING ':' value ;

array: '[' value (',' value)* ']'  # ArrayOfValues
     | '[' ']'                     # EmptyArray
     ;

value: STRING      # String
     | NUMBER      # Atom
     | object      # ObjectValue
     | array       # ArrayValue
     | 'true'      # Atom
     | 'false'     # Atom
     | 'null'      # Atom
     ;

// Lexer rules
STRING: '"' (ESC | SAFECODEPOINT)* '"';

fragment ESC: '\\' (["\\/bfnrt] | UNICODE);
fragment UNICODE: 'u' HEX HEX HEX HEX;
fragment HEX: [0-9a-fA-F];
fragment SAFECODEPOINT: ~["\\\u0000-\u001F];

NUMBER: '-'? INT ('.' [0-9]+)? EXP?;
fragment INT: '0' | [1-9] [0-9]*;
fragment EXP: [Ee] [\-+]? [0-9]+;

WS: [ \t\n\r]+ -> skip;
