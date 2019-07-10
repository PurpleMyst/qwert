from strformat import fmt
from strutils import Digits, IdentStartChars, IdentChars, Whitespace, isSpaceAscii
from parseutils import parseInt
from sequtils import allIt
from value import Value, ValueKind

type
  Parser = ref object
    code: string
    len: int

  ParseError = ref object of CatchableError

proc peek(parser: Parser): char = parser.code[0]

proc skip(parser: Parser, n: int) =
  parser.code = parser.code[n..high(parser.code)]

proc char(parser: Parser): char =
  result = parser.peek
  parser.skip(1)

proc value(parser: Parser): Value

proc number(parser: Parser): Value =
  result = Value(kind: vkNumber)
  let chars = parseInt(parser.code, result.n)
  parser.skip(chars)

proc identifier(parser: Parser): Value =
  result = Value(kind: vkIdentifier)

  let startChar = parser.char
  assert startChar in IdentStartChars
  result.ident.add startChar

  while parser.peek in IdentChars:
    result.ident.add parser.char

  assert result.ident.len != 0

proc sexpr(parser: Parser): Value =
  result = Value(kind: vkSExpr)

  let lparen = parser.char
  assert lparen == '('

  while parser.code[0] != ')':
    result.contents.add parser.value

  let rparen = parser.char
  assert rparen == ')'

proc string(parser: Parser): Value =
  result = Value(kind: vkString)
  let quote = parser.char
  assert quote == '"'

  while parser.peek != quote:
    result.s.add parser.char

  discard parser.char

proc value(parser: Parser): Value =
  case parser.peek
    of '(': return parser.sexpr
    of Digits: return parser.number
    of Whitespace:
      discard parser.char
      return parser.value
    of '"': return parser.string
    of IdentStartChars: return parser.identifier
    else: raise ParseError(msg: fmt"Unexpected character {parser.peek}")

proc parse*(code: string): seq[Value] =
  var parser = Parser(code: code, len: code.len)

  while not parser.code.allIt(it.isSpaceAscii):
    result.add parser.value
