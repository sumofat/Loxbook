package main

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import con "packages/containers"
import compiler "compiler"

main :: proc(){
	using compiler
	using fmt
	args := os.args//: []string = …
	println(args)
	if len(args) > 2{
		fmt.println("Usage: jlox [script]")
	}else if len(args) == 2{
		//run file
//		compiler.interpret(args[1])
	//	run_file(args[1])
	}else{
		//run prompts
//		run_prompt()
	}
	test_chunk := compiler.init_chunk()
	test_value := Object(u32(2))
	constant := chunk_add_constant(&test_chunk,test_value)
	emit_load_int(&test_chunk.code,u32(constant),test_value.(u32))

	emit_return(&test_chunk.code)


	for code in test_chunk.code.buffer{
		println(code)
	}

	println("writing bytes")
	handle,err := os.open("out.lox",os.O_RDWR,os.O_CREATE)
	println("open ERROR ",err)
	out_bytes := con.buf_get_slice_of_type(&test_chunk.code,u8)//mem.slice_data_cast([]u8,result.code[:])

	write_result,errno := os.write(handle,out_bytes)
	println("wrrite result ",write_result," errno: ",errno)
	println("Bytes written with handle ",handle)


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
/*
run :: proc(source : string){
	s = compiler.scanner_init(source)
	scanner_scan(&s)

	for token in s.tokens.buffer{
		fmt.println(token)
	}
	//tokenize
	if had_error{os.exit(1)}
}
*/
