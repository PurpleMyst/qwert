from strformat import fmt

type
  ValueKind* = enum
    vkString
    vkIdentifier
    vkNumber
    vkSExpr

  Value* = object
    case kind*: ValueKind
    of vkString:
      s*: string
    of vkIdentifier:
      ident*: string
    of vkNumber:
      n*: int
    of vkSExpr:
      contents*: seq[Value]

  IDontKnowError = ref object of CatchableError

func `$`*(kind: ValueKind): string =
  case kind
    of vkString: return "const char*"
    of vkNumber: return "int"
    else: raise IDontKnowError(msg: fmt"unknown typename for kind {kind.repr}")
