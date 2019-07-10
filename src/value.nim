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
