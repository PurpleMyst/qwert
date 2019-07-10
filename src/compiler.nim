from strformat import fmt
import tables
import value

type
  Compiler = ref object
    variableTypes: Table[string, ValueKind]
    returnTypes: Table[string, ValueKind]

  CompileError = ref object of CatchableError

# Map a type name to its discriminant equivalent
func typename(typename: string): ValueKind =
  case typename
    of "string": return vkString
    of "int": return vkNumber
    else: raise CompileError(msg: fmt"unknown typename: {typename}")

# Infer the type of an expression
func expressionType(self: Compiler, value: Value): ValueKind =
  case value.kind:
    of vkIdentifier: return self.variableTypes[value.ident]
    of vkSExpr: return self.returnTypes[value.contents[0].ident]
    else: return value.kind

proc compile(self: Compiler, value: Value): string

# Compile a function definition
proc compileFunction(self: Compiler, name: Value, args: Value, returnType: Value, body: openarray[Value]): string =
  assert returnType.kind == vkIdentifier
  assert name.kind == vkIdentifier

  self.returnTypes[name.ident] = returnType.ident.typename

  result &= $returnType.ident.typename

  result &= ' '

  result &= name.ident

  result &= '('

  assert args.kind == vkSExpr
  for idx, arg in args.contents:
    assert arg.kind == vkSExpr

    assert arg.contents[0].kind == vkIdentifier
    assert arg.contents[1].kind == vkIdentifier

    result &= $self.expressionType(arg.contents[0])
    result &= ' '
    result &= arg.contents[1].ident

  result &= ") {\n"

  for value in body:
    result &= self.compile(value)
    result &= ';'

  result &= "\n}"

proc compileSet(self: Compiler, lhs: Value, rhs: Value): string =
  assert lhs.kind == vkIdentifier

  self.variableTypes[lhs.ident] = self.expressionType(rhs)

  result &= $self.expressionType(rhs)
  result &= ' '
  result &= self.compile(lhs)
  result &= " = "
  result &= self.compile(rhs)
  result &= ';'

# Compile a value to an expression
proc compile(self: Compiler, value: Value): string =
  case value.kind
    of vkString: return '"' & value.s & '"'
    of vkIdentifier: return value.ident
    of vkNumber: return $value.n
    of vkSExpr:
      let head = value.contents[0]
      assert head.kind == vkIdentifier

      # builtins
      case head.ident:
        # (fn name args body ...)
        of "fn":
          result &= self.compileFunction(
            name = value.contents[1],
            args = value.contents[2],
            returnType = value.contents[3],
            body = value.contents[4..high(value.contents)],
          )

        # (set name value)
        of "set":
          result &= self.compileSet(
            lhs = value.contents[1],
            rhs = value.contents[2],
          )

        else:
          result &= head.ident
          result &= '('

          for idx, item in value.contents[1..high(value.contents)]:
            if idx != 0:
              result &= ", "

            result &= self.compile(item)

          result &= ')'

proc compile*(values: openarray[Value]): string =
  var compiler = Compiler()
  for value in values: result &= compiler.compile(value)
