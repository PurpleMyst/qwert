import parser
import compiler

when isMainModule:
  echo(compile(parse("""(echo "hello, world")""")))
