complete -c aws -f -a '
  (begin
    set -lx COMP_LINE (commandline -cp)
    set -lx COMP_POINT (string length -- (commandline -cp))
    ~/.local/bin/aws_completer
  end)
'
