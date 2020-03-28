import asyncdispatch
import jester
import os
import posix
import strutils

onSignal(SIGABRT):
    ## Handle SIGABRT from systemd
    # Lines printed to stdout will be received by systemd and logged
    # Start with "<severity>" from 0 to 7
    echo "<2>Received SIGABRT"
    quit(1)

onSignal(SIGINT):
    echo "<2>Recieved SIGINT"
    quit(1)

#include "templates/main.html"

router myrouter:
    get "/":
        resp "A cool content"

    get "/hello/@name":
        var name: string = @"name"
        # This matches "/hello/fred" and "/hello/bob".
        # In the route ``@"name"`` will be either "fred" or "bob".
        # This can of course match any value which does not contain '/'.
        echo name
        resp "hello " & name

proc main() =
    let port = parseInt("80").Port
    let staticDir = joinPath(getCurrentDir(), "../public")
    let settings = newSettings(port=port, staticDir=staticDir)
    var jester = initJester(myrouter, settings=settings)
    jester.serve()
    
when isMainModule:
    main()