from strformat import fmt

type
  ValueType* = enum
    vtString
    vtIdentifier
    vtNumber
    vtSExpr

  Value* = object
    case ty*: ValueType
    of vtString:
      s*: string
    of vtIdentifier:
      ident*: string
    of vtNumber:
      n*: int
    of vtSExpr:
      contents*: seq[Value]

  IDontKnowError = ref object of CatchableError

func `$`*(ty: ValueType): string =
  case ty
    of vtString: return "const char*"
    of vtNumber: return "int"
    else: raise IDontKnowError(msg: fmt"unknown typename for type {ty.repr}")
