from strformat import fmt
import tables
import value

type
  Compiler = ref object
    variableTypes: Table[string, ValueType]
    returnTypes: Table[string, ValueType]

  CompileError = ref object of CatchableError

# Map a type name to its discriminant equivalent
func typename(typename: string): ValueType =
  case typename
    of "string": return vtString
    of "int": return vtNumber
    else: raise CompileError(msg: fmt"unknown typename: {typename}")

# Infer the type of an expression
func expressionType(self: Compiler, value: Value): ValueType =
  case value.ty:
    of vtIdentifier: return self.variableTypes[value.ident]
    of vtSExpr: return self.returnTypes[value.contents[0].ident]
    else: return value.ty

proc compile(self: Compiler, value: Value): string

# Compile a function definition
proc compileFunction(self: Compiler, name: Value, args: Value, returnType: Value, body: openarray[Value]): string =
  assert returnType.ty == vtIdentifier
  assert name.ty == vtIdentifier

  self.returnTypes[name.ident] = returnType.ident.typename

  result &= $returnType.ident.typename

  result &= ' '

  result &= name.ident

  result &= '('

  assert args.ty == vtSExpr
  for idx, arg in args.contents:
    assert arg.ty == vtSExpr

    assert arg.contents[0].ty == vtIdentifier
    assert arg.contents[1].ty == vtIdentifier

    result &= $self.expressionType(arg.contents[0])
    result &= ' '
    result &= arg.contents[1].ident

  result &= ") {\n"

  for value in body:
    result &= self.compile(value)
    result &= ';'

  result &= "\n}"

proc compileSet(self: Compiler, lhs: Value, rhs: Value): string =
  assert lhs.ty == vtIdentifier

  self.variableTypes[lhs.ident] = self.expressionType(rhs)

  result &= $self.expressionType(rhs)
  result &= ' '
  result &= self.compile(lhs)
  result &= " = "
  result &= self.compile(rhs)
  result &= ';'

# Compile a value to an expression
proc compile(self: Compiler, value: Value): string =
  case value.ty
    of vtString: return '"' & value.s & '"'
    of vtIdentifier: return value.ident
    of vtNumber: return $value.n
    of vtSExpr:
      let head = value.contents[0]
      assert head.ty == vtIdentifier

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
