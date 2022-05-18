package compiler

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import con "../packages/containers"

TokenType :: enum{
	// Single-character tokens.
	LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
	COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

	// One or two character tokens.
	BANG, BANG_EQUAL,
	EQUAL, EQUAL_EQUAL,
	GREATER, GREATER_EQUAL,
	LESS, LESS_EQUAL,

	// Literals.
	IDENTIFIER, STRING_TYPE, NUMBER,

	// Keywords.
	AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
	PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

	ERROR,

	EOF,
}

Token :: struct{
	type : TokenType,
	lexeme : string,
	obj : Object,
	line : int,
}


token_init :: proc(type : TokenType,lexeme : string,line : int)-> Token{
	result : Token = {type,lexeme,"",line}
	return result
}

token_to_string :: proc(token : Token){
	//return fmt.printf(token)
}
