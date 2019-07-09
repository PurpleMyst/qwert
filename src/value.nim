type
  ValueKind* = enum
    String
    Identifier
    SExpr
    Number

  Value* = object
    case kind*: ValueKind
    of String:
      s*: string
    of Identifier:
      ident*: string
    of Number:
      n*: int
    of SExpr:
      contents*: seq[Value]
