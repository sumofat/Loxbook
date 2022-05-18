package compiler

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import con "../packages/containers"

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

Precedence :: enum {
	PREC_NONE,
	PREC_ASSIGNMENT,  // =
	PREC_OR,          // or
	PREC_AND,         // and
	PREC_EQUALITY,    // == !=
	PREC_COMPARISON,  // < > <= >=
	PREC_TERM,        // + -
	PREC_FACTOR,      // * /
	PREC_UNARY,       // ! -
	PREC_CALL,        // . ()
	PREC_PRIMARY,
}

Chunk :: struct {
	constants : con.Buffer(Object),
	code : con.Buffer(u32),
} 

Parser :: struct {
	current  : Token,
	previous : Token,
	panic_mode : bool,
	had_error : bool,
}

Object :: union{
	rawptr,
	string,
	f64,
	u32,
	i32,
}

Scanner :: struct{
	source : string,
	tokens : con.Buffer(Token),
	start : int,
	current : int,
	line : int,
	keywords : map[string]TokenType,
}

parser : Parser

init_chunk :: proc()-> Chunk{
	result : Chunk
	result.code = con.buf_init(1,u32)
	result.constants = con.buf_init(1,Object)
	return result
}

end :: proc(buf : ^con.Buffer(u32)){
	//for now we just print 0 as a return code
	emit_load_int(buf,1,'0')
	emit_putchar(buf,1)
	emit_return(buf)
}

chunk_add_constant :: proc(chunk : ^Chunk,value : Object)-> int{
	using con
	assert(chunk != nil)
	buf_push(&chunk.constants,value)
	return int(buf_len(chunk.constants) - 1)
}
error_at :: proc(token : ^Token,message : string) {
	using fmt
	if parser.panic_mode {return}
	tprintf("[line %d] Error", token.line);

	if (token.type == .EOF) {
		tprintf(" at end");
	} else if (token.type == .ERROR) {
		// Nothing.
	} else {
		tprintf(" at '%.*s'", token.lexeme);
	}

	tprintf(": %s\n", message);
	parser.had_error = true;
}
error_at_current :: proc(message : string){
	  error_at(&parser.current, message);
}

advance :: proc(using scanner : ^Scanner){
	parser.previous = parser.current
	for {
		parser.current = scanner_scan_token(scanner)
		if parser.current.type != .ERROR{break}
		error_at_current("compiler error")
	}
}

expression :: proc(using scanner : ^Scanner){
	compiler_parse_precedence(scanner,.PREC_ASSIGNMENT)
}

unary :: proc(buf : ^con.Buffer(u32),using scanner : ^Scanner){
	operator_type := parser.previous.type	
	expression(scanner)

	compiler_parse_precedence(scanner,.PREC_UNARY)

	#partial switch operator_type{
		case .MINUS:{
			emit_load_int(buf,1,-u32(parser.current.obj.(f64)))
		}
		case:return
	}
}

grouping :: proc(using scanner : ^Scanner){
	expression(scanner)
	consume(scanner,.RIGHT_PAREN,"Expcect ')' after expression.")
}

number :: proc(buf : ^con.Buffer(u32)){
	value := parser.previous.obj
	emit_load_int(buf,1,u32(value.(f64)))
}

consume :: proc(scanner : ^Scanner,type : TokenType,message : string){
	if parser.current.type == type{
		advance(scanner)
		return
	}
	error_at_current(message)
}

compiler_parse_precedence :: proc(using scanner : ^Scanner,pres  : Precedence){
}

compile :: proc(source : string,output : ^con.Buffer(u32))-> bool{
	s := scanner_init(source)
	advance(&s)
	expression(&s)
	consume(&s,TokenType.EOF,"Expect end of expression")
	end(output)
	return parser.had_error
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
