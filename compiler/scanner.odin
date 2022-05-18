package compiler

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import con "../packages/containers"

s : Scanner
had_error : bool

scanner_init :: proc(source : string)-> Scanner{
	result : Scanner
	result.tokens = con.buf_init(1,Token)
	result.source = strings.clone(source)
	result.line = 1
	km := make(map[string]TokenType)
	km["and"] = .AND
	km["class"] = .CLASS
	km["else"] = .ELSE
	km["false"] = .FALSE
	km["for"] = .FOR
	km["fun"] = .FUN
	km["if"] = .IF
	km["nil"] = .NIL
	km["or"] = .OR
	km["print"] = .PRINT
	km["return"] = .RETURN
	km["super"] = .SUPER
	km["this"] = .THIS
	km["true"] = .TRUE
	km["var"] = .VAR
	km["while"] = .WHILE

	result.keywords = km
	return result
}

scanner_advance :: proc(using scanner : ^Scanner)-> u8 {
	result := source[current]
	current += 1
	return result
}

scanner_add_token_type_literal :: proc(using scanner : ^Scanner,type : TokenType,obj : Object){
	con.buf_push(&tokens,Token{type,"",obj,line})
}

scanner_add_token_type :: proc(using scanner : ^Scanner,type : TokenType){
	con.buf_push(&tokens,Token{type,"",nil,line})
}

scanner_add_token :: proc{scanner_add_token_type,scanner_add_token_type_literal}

scanner_is_at_end :: proc(scanner : ^Scanner)-> bool{
	using scanner
	return current >= len(source)
}

scanner_scan :: proc(using scanner : ^Scanner){
	for !scanner_is_at_end(scanner){
		start = current
		scanner_scan_token(scanner)
	}
	con.buf_push(&tokens,Token{.EOF,"","",line})
}
scanner_scan_token :: proc(using scanner : ^Scanner)-> Token{
	c := scanner_advance(scanner)
	switch (c){
		case '(' : scanner_add_token_type(scanner,.LEFT_PAREN)
		case ')' : scanner_add_token_type(scanner,.RIGHT_PAREN)
		case '{' : scanner_add_token_type(scanner,.LEFT_BRACE)
		case '}' : scanner_add_token_type(scanner,.RIGHT_BRACE)
		case ',' : scanner_add_token_type(scanner,.COMMA)
		case '.' : scanner_add_token_type(scanner,.DOT)
		case '-' : scanner_add_token_type(scanner,.MINUS)
		case '+' : scanner_add_token_type(scanner,.PLUS)
		case ';' : scanner_add_token_type(scanner,.SEMICOLON)
		case '*' : scanner_add_token_type(scanner,.STAR)
		case '!' : {
			scanner_add_token(scanner,scanner_match(scanner,'=') ? .BANG_EQUAL : .BANG)
		}
		case '=' : {
			scanner_add_token(scanner,scanner_match(scanner,'=') ? .EQUAL_EQUAL : .EQUAL)
		}
		case '<' : {
			scanner_add_token(scanner,scanner_match(scanner,'=') ? .LESS_EQUAL : .LESS)
		}
		case '>' : {
			scanner_add_token(scanner,scanner_match(scanner,'=') ? .GREATER_EQUAL : .GREATER)
		}
		case '/':{
			if scanner_match(scanner,'/'){
				//comment
				for scanner_peek(scanner) != '\n' && !scanner_is_at_end(scanner){
					scanner_advance(scanner)
				}
			}else{
				scanner_add_token(scanner,.SLASH)
			}
		}
		case ' ':line+= 1
		case '\r':line += 1
		case '\t':line += 1
		case '\n':line += 1
		case '"': scanner_string(scanner)
		case: {
			if scanner_is_digit(scanner,c){
				scanner_number(scanner)
			}else if scanner_is_alpha(scanner,c){
				scanner_identifier(scanner)
			}else{
				scanner_add_token(scanner,.ERROR)
				//error(line,"Unexpected character.")
			}
		}
	}
	return con.buf_peek(&tokens)
}

scanner_is_alpha :: proc(using scanner : ^Scanner,c : u8)-> bool{
	return (c >= 'a' && c <= 'z') || 
			(c >= 'A' && c <= 'Z') || 
			(c == '_')
}

scanner_is_alpha_numeric :: proc(using scanner : ^Scanner,c : u8)-> bool{
	return scanner_is_alpha(scanner,c) || scanner_is_digit(scanner,c)
}

scanner_identifier :: proc(using scanner : ^Scanner){
	for scanner_is_alpha_numeric(scanner,scanner_peek(scanner)){
		scanner_advance(scanner)
	}
	text := source[start : current]
	type := keywords[text]
	if type == nil{
		type = .IDENTIFIER
	}
	scanner_add_token(scanner,type)
}

//add column error reporting
report :: proc(line : int,where_at : string,message : string){
	using fmt
	println("[line ",line,"]Error",where_at,": ",message)
	had_error = true
}

scanner_is_digit :: proc(using scanner : ^Scanner,c : u8)-> bool{
	return c >= '0' && c < '9'
}

scanner_number :: proc(using scanner : ^Scanner){
}

error :: proc(line : int,message : string){
	report(line,"",message)
}

scanner_string :: proc(using scanner : ^Scanner){
	for scanner_peek(scanner) != '"' && !scanner_is_at_end(scanner){
		if scanner_peek(scanner) == '\n' { line += 1}
		scanner_advance(scanner)
	}

	if scanner_is_at_end(scanner) {
		error(line,"Unterminated string")
	}
	scanner_advance(scanner)

	value := source[start + 1 : current -1]//strings.sub_string(source,start + 1 , current - 1)
	scanner_add_token(scanner,TokenType.STRING_TYPE,value)
}

scanner_peek :: proc(using scanner : ^Scanner) -> u8{
	if scanner_is_at_end(scanner){
		return u8('\x00')
	}
	return source[current]
}
scanner_peek_next :: proc(using scanner : ^Scanner)-> u8{
	if current + 1 >= len(source){
		return u8('\x00') 
	}
	return source[current + 1]
}
scanner_match :: proc(using scanner : ^Scanner,expected : u8)-> bool{
	if scanner_is_at_end(scanner){
		return false
	}
	if source[current] != expected{return false}
	current += 1
	return true
}

