from strformat import fmt
import tables
import value

type
  Compiler = ref object
    variableTypes: Table[string, ValueKind]
    returnTypes: Table[string, ValueKind]

  CompileError = ref object of CatchableError


proc compile(self: Compiler, name: Value, args: Value, returnType: Value, body: openarray[Value]): string
proc compile(self: Compiler, value: Value): string =
  case value.kind
    of vkString: return '"' & value.s & '"'
    of vkIdentifier: return value.ident
    of vkNumber: return $value.n
    of vkSExpr:
      let head = value.contents[0]

      if head.kind != vkIdentifier:
        raise CompileError(msg: "Only functions are callable")

      # builtins
      case head.ident:
        # (fn name args body ...)
        of "fn":
          result &= self.compile(
            name = value.contents[1],
            args = value.contents[2],
            returnType = value.contents[3],
            body = value.contents[4..high(value.contents)]
          )
          return

      result &= head.ident
      result &= '('

      for idx, item in value.contents[1..high(value.contents)]:
        if idx != 0:
          result &= ", "

        result &= self.compile(item)

      result &= ')'

func identifierToCType(value: Value): string =
  assert value.kind == vkIdentifier
  case value.ident
    of "string": return "const char*"
    of "int": return "int"
    else: raise CompileError(msg: fmt"unsupported type {value.repr}")

proc compile(self: Compiler, name: Value, args: Value, returnType: Value, body: openarray[Value]): string =
  assert returnType.kind == vkIdentifier
  result &= identifierToCType(returnType)

  result &= ' '

  assert name.kind == vkIdentifier
  result &= name.ident

  result &= '('

  assert args.kind == vkSExpr
  for idx, arg in args.contents:
    assert arg.kind == vkSExpr
    assert arg.contents[1].kind == vkIdentifier

    result &= identifierToCType(arg.contents[0])
    result &= ' '
    result &= arg.contents[1].ident

  result &= ") {\n"

  for value in body:
    result &= self.compile(value)
    result &= ';'

  result &= "\n}"

proc compile*(values: openarray[Value]): string =
  var compiler = Compiler()
  for value in values: result &= compiler.compile(value)
