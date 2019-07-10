import parser
import compiler

when isMainModule:
  echo(compile(parse("""
    (set x 2)

    (fn main () int
      (echo x)
      (return 0))
  """)))
