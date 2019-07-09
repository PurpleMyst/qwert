from strformat import fmt
from strutils import repeat
from value import Value, ValueKind

type
  Compiler = ref object
    headers: seq[string]
    code: string
    depth: Natural

  CompileError = ref object of CatchableError

proc compile(compiler: Compiler, value: Value)

proc compileEcho(compiler: Compiler, args: seq[Value]) =
  var fmt = ""

  compiler.code &= "printf(\""

  for i, value in args:
    if i != 0:
      fmt &= ' '

    case value.kind:
      of String: fmt &= "%s"
      of Number: fmt &= "%d"
      else: raise CompileError(msg: fmt"unsupported echo arg {value.repr}")

  compiler.code &= fmt
  compiler.code &= "\\n\""

  for i, value in args:
    compiler.code &= ", "
    compiler.compile(value)

  compiler.code &= ")"

  compiler.headers &= "stdio.h"

proc compile(compiler: Compiler, contents: seq[Value]) =
  if contents[0].kind == Identifier:
    case contents[0].ident:
      of "echo": compiler.compileEcho(contents[1..high(contents)])
      else: raise CompileError(msg: fmt"unsupported function {contents.repr}")
  else:
    raise CompileError(msg: fmt"unsupported sexpr {contents.repr}")

proc compile(compiler: Compiler, value: Value) =
  compiler.depth += 1
  case value.kind:
    of String: compiler.code &= '"' & value.s & '"'
    of Identifier: compiler.code &= value.ident
    of Number: compiler.code &= $value.n
    of SExpr: compiler.compile(value.contents)
  compiler.depth -= 1

  if compiler.depth == 0:
    compiler.code &= ';'

proc compile*(value: Value): string =
  var compiler = Compiler()
  compiler.code &= "int main(void) {\n"
  compiler.compile(value)
  compiler.code &= "\n}"
  for header in compiler.headers:
    compiler.code = fmt"#include <{header}>{'\n'}" & compiler.code
  return compiler.code
