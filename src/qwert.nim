import parser

when isMainModule:
  echo(parser.parse("""(echo "hello, world")"""))
