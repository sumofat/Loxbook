package main
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import con "packages/containers"

had_error : bool
main :: proc(){
	using fmt


	args := os.args//: []string = …

	println(args)
	
	if len(args) > 2{
		fmt.println("Usage: jlox [script]")
	}else if len(args) == 2{
		//run file
		run_file(args[1])
	}else{
		//run prompts
		run_prompt()
	}
}

run_file :: proc(file : string){
	using fmt
	if bytes,ok := os.read_entire_file_from_filename(file);ok == true{
		println("Executing file ",file)
	}else{
		println("Could not file ",file)
	}
}

run_prompt :: proc(){

	for {
		stdin := os.stdin;
		buffer:= make([]byte, 100);
		fmt.println("stdin handle:", stdin);
		i, err := os.read(stdin, buffer);
		fmt.println(i, err);
		fmt.println(buffer);
	}
}

run :: proc(){

	//tokenize
	if had_error{os.exit(1)}
}

error :: proc(line : int,message : string){
	report(line,"",message)
}

//add column error reporting
report :: proc(line : int,where_at : string,message : string){
	using fmt
	println("[line ",line,"]Error",where_at,": ",message)
	had_error = true
}

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
	IDENTIFIER, STRING, NUMBER,

	// Keywords.
	AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
	PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

	EOF,
}

Token :: struct{
	type : TokenType,
	lexeme : string,
	literal : string,
	line : int,
}

token_init :: proc(type : TokenType,lexeme : string,line : int)-> Token{
	result : Token = {type,lexeme,"",line}
	return result
}

token_to_string :: proc(token : Token){
	//return fmt.printf(token)
}

Scanner :: struct{
	source : string,
	tokens : con.Buffer(Token),
	start : int,
	current : int,
	line : int,
}

scanner_init :: proc(source : string)-> Scanner{

	result : Scanner
	result.tokens = con.buf_init(1,Token)
	result.source = strings.clone(source)
	result.line = 1
	return result
}

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

scanner_advance :: proc(using scanner : ^Scanner)-> u8 {
	result := source[current]
	current += 1
	return result
}

scanner_add_token_type_literal :: proc(using scanner : ^Scanner,type : TokenType,identifier : string){
	con.buf_push(&tokens,Token{type,"",identifier,line})
}

scanner_add_token_type :: proc(using scanner : ^Scanner,type : TokenType){
	con.buf_push(&tokens,Token{type,"","",line})
}

scanner_add_token :: proc{scanner_add_token_type,scanner_add_token_type_literal}

scanner_scan_token :: proc(using scanner : ^Scanner){
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
		case: error(line,"Unexpected character.")
	}
}
