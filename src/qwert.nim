import parser
import compiler

when isMainModule:
  echo(compile(parse("""
    (fn twotimes ((int x)) int
      (return (* x 2)))

    (fn main () int
      (puts "hello, world")
      (return 0))
  """)))
