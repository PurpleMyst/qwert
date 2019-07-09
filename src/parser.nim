import strformat
import strutils
from parseutils import nil

type
  ValueKind = enum
    String
    Identifier
    SExpr
    Number

  Value = object
    case kind*: ValueKind
    of String:
      s: string
    of Identifier:
      ident: string
    of Number:
      n: int
    of SExpr:
      contents: seq[Value]

  Parser = ref object
    code: string
    len: int

proc peek(parser: Parser): char = parser.code[0]

proc skip(parser: Parser, n: int) =
  parser.code = parser.code[n..high(parser.code)]

proc char(parser: Parser): char =
  result = parser.peek
  parser.skip(1)

proc value(parser: Parser): Value

proc number(parser: Parser): Value =
  result = Value(kind: Number)
  let n = parseutils.parseInt(parser.code, result.n)
  parser.skip(n)

proc identifier(parser: Parser): Value =
  result = Value(kind: Identifier)

  while parser.peek.isAlphaAscii:
    result.ident.add parser.char

  assert result.ident.len != 0

proc sexpr(parser: Parser): Value =
  let lparen = parser.char
  assert lparen == '('

  result = Value(kind: SExpr)

  while parser.code[0] != ')':
    result.contents.add parser.value

  let rparen = parser.char
  assert rparen == ')'

proc string(parser: Parser): Value =
  let quote = parser.char
  assert quote == '"'

  result = Value(kind: String)

  while parser.peek != quote:
    result.s.add parser.char

  discard parser.char

proc value(parser: Parser): Value =
  case parser.peek
    of '(': return parser.sexpr
    of Digits: return parser.number
    of ' ':
      discard parser.char
      return parser.value
    of '"': return parser.string
    else: return parser.identifier

proc parse*(code: string): Value = Parser(code: code, len: code.len).sexpr
