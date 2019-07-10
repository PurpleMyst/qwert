import parser
import compiler

when isMainModule:
  echo(compile(parse("""
    (set x 2)

    (fn main () int
      (printf "x = %d\n" x)
      (return 0))
  """)))
