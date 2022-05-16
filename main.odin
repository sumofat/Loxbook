package main
import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import con "packages/containers"


Scanner :: struct{
	source : string,
	tokens : con.Buffer(Token),
	start : int,
	current : int,
	line : int,
	keywords : map[string]TokenType,
}

Object :: union{
	rawptr,
	string,
	f64,
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

InterpretResult :: enum {
	INTERPRET_OK,
	INTERPRET_COMPILE_ERROR,
	INTERPRET_RUNTIME_ERROR,
}

MINIVM_Opcode :: enum u32{
	VM_OPCODE_EXIT = 0,
	VM_OPCODE_REG = 1,
	VM_OPCODE_INT = 2,
	VM_OPCODE_JUMP = 3,
	VM_OPCODE_FUNC = 4,
	VM_OPCODE_ADD = 5,
	VM_OPCODE_SUB = 6,
	VM_OPCODE_MUL = 7,
	VM_OPCODE_DIV = 8,
	VM_OPCODE_MOD = 9,
	VM_OPCODE_CALL = 10,
	VM_OPCODE_RET = 11,
	VM_OPCODE_PUTCHAR = 12,
	VM_OPCODE_BB = 13,
	VM_OPCODE_BEQ = 14,
	VM_OPCODE_BLT = 15,
	VM_OPCODE_DCALL = 16,
	VM_OPCODE_INTF = 17,
	VM_OPCODE_TCALL = 18,
	VM_OPCODE_PAIR = 19,
	VM_OPCODE_FIRST = 20,
	VM_OPCODE_SECOND = 21,
}

ValueArray :: struct($type : typeid){
	values : con.Buffer(type),
}

Chunk :: struct {
	constant_ints : ValueArray(int),
	code : con.Buffer(u32),
} 

s : Scanner
had_error : bool
main :: proc(){
	using fmt

	args := os.args//: []string = …

	println(args)
	
	if len(args) > 2{
		fmt.println("Usage: jlox [script]")
	}else if len(args) == 2{
		//run file
		interpret(args[1])
//		run_file(args[1])
	}else{
		//run prompts
		run_prompt()
	}
}

init_chunk :: proc(){
	result : Chunk
	result.code = con.buf_init(1,u32)
	result.constant_ints.values = con.buf_init(1,int)
}

end_compiler :: proc(buf : ^con.Buffer(u32)){
	//for now we just print 0 as a return code
	emit_load_int(buf,1,'0')
	emit_putchar(buf,1)
	emit_return(buf)
}

chunk_add_constant_int :: proc(chunk : ^Chunk,value : int){
	using con
	assert(chunk != nil)
	buf_push(&chunk.constant_ints.values,value)
}
Parser :: struct {
	current : Token,
	previous : Token,
}

parser : Parser

advance :: proc(using scanner : ^Scanner){
	parser.previous = parser.current
	for {
		parser.current = scanner_scan_token(scanner)
		if parser.current.type != .ERROR{break}
		//compiler_error_at_current(parser.current.token)
	}
}

expression :: proc(){}

grouping :: proc(){
}

compiler_number :: proc(buf : ^con.Buffer(u32)){
	value := parser.previous.obj
	emit_load_int(buf,1,u32(value.(f64)))
}

consume :: proc(scanner : ^Scanner,type : TokenType,message : string){
	if parser.current.type == type{
		advance(scanner)
		return
	}
	
	//error_at_current
}

compile :: proc(source : string,output : ^con.Buffer(u32))-> bool{
	s := scanner_init(source)
	advance(&s)
	expression()
	consume(&s,TokenType.EOF,"Expect end of expression")
	end_compiler(output)
	return false
}

interpret :: proc(file : string)-> (Chunk,bool){
	result : Chunk
	result.code = con.buf_init(1,u32)
	using fmt
	if bytes,ok := os.read_entire_file_from_filename(file);ok == true{
		println("Executing file ",file)
		//	run(string(bytes))
		if !compile(string(bytes),&result.code){
			return result,false
		}
		handle,err := os.open("out.lox",os.O_RDWR,os.O_CREATE)

		out_bytes := con.buf_get_slice_of_type(&result.code,u8)//mem.slice_data_cast([]u8,result.code[:])
		os.write(handle,out_bytes)
		return result,true
	}else{
		println("Could not file ",file)
		return result,false
	}

	return result,false
}

emit_putchar ::proc(buf : ^con.Buffer(u32),in_reg : u32){
	using con
	assert(buf != nil)
	opcode : u32 = u32(MINIVM_Opcode.VM_OPCODE_PUTCHAR)
	buf_push(buf,opcode)
	buf_push(buf,opcode)
}

emit_return :: proc(buf : ^con.Buffer(u32)){
	using con
	assert(buf != nil)
	opcode : u32 = u32(MINIVM_Opcode.VM_OPCODE_RET)
	buf_push(buf,opcode)
}

emit_load_int :: proc(buf : ^con.Buffer(u32),reg : u32,value : u32){
	using con
	assert(buf != nil)
	opcode : u32 = u32(MINIVM_Opcode.VM_OPCODE_INT)
	buf_push(buf,opcode)
	buf_push(buf,reg)
	buf_push(buf,value)
}

run_file :: proc(file : string){
	using fmt
	if bytes,ok := os.read_entire_file_from_filename(file);ok == true{
		println("Executing file ",file)
		run(string(bytes))
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

run :: proc(source : string){
	s = scanner_init(source)
	scanner_scan(&s)

	for token in s.tokens.buffer{
		fmt.println(token)
	}
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
token_init :: proc(type : TokenType,lexeme : string,line : int)-> Token{
	result : Token = {type,lexeme,"",line}
	return result
}

token_to_string :: proc(token : Token){
	//return fmt.printf(token)
}

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

scanner_add_token_type_literal :: proc(using scanner : ^Scanner,type : TokenType,obj : Object){
	con.buf_push(&tokens,Token{type,"",obj,line})
}

scanner_add_token_type :: proc(using scanner : ^Scanner,type : TokenType){
	con.buf_push(&tokens,Token{type,"",nil,line})
}

scanner_add_token :: proc{scanner_add_token_type,scanner_add_token_type_literal}

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

scanner_is_digit :: proc(using scanner : ^Scanner,c : u8)-> bool{
	return c >= '0' && c < '9'
}

scanner_number :: proc(using scanner : ^Scanner){
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

scanner_match :: proc(using scanner : ^Scanner,expected : u8)-> bool{
	if scanner_is_at_end(scanner){
		return false
	}
	if source[current] != expected{return false}
	current += 1
	return true
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
