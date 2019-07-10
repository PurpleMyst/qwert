import parser
import compiler

when isMainModule:
  echo(compile(parse("""
    (fn main () int
      (if 0
        (begin
          (set x "hi")
          (echo x))

        (begin
          (set y "hello")
          (echo "not x")))

      (return 0))
  """)))
