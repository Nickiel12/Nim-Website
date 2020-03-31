import asyncdispatch
import jester
import os
import posix
import strutils
import asyncfile, asyncstreams
import strutils
import ws, ws/jester_extra
import times

onSignal(SIGABRT):
    ## Handle SIGABRT from systemd
    # Lines printed to stdout will be received by systemd and logged
    # Start with "<severity>" from 0 to 7
    echo "<2>Received SIGABRT"
    quit(1)

onSignal(SIGINT):
    echo "<2>Recieved SIGINT"
    quit(1)

include "templates/Home.html"
include "templates/success.html"

router myrouter:
    get "/audition/@name":
        resp(home_page(@"name"))
  
    get "/ws-upload/@name":
        echo "connected"
        discard existsOrCreateDir("./../../Documents/auditions/")
        discard existsOrCreateDir("./../../Documents/auditions/" & @"name")
        echo "Saving to file: ", absolutePath(joinPath("./../..","/Documents/auditions/" & @"name"))
        try:
            var wsconn = await newWebSocket(request)
            
            await wsconn.send("send the filename")
            var fname = await wsconn.receiveStrPacket()
            let fileExt = splitFile(fname).ext
            var part = await wsconn.receiveStrPacket()

            echo "ding 1"
            echo fname
            echo fileExt
            echo part
            let fileName = "loaded_files/" & @"name" & "/" & part & " - " & format(getTime(), "d MMMM yyyy HH-mm") & fileExt
            echo "Recieved, saving file to ", filename
            var f = openAsync(fileName, fmWrite)
            echo "ding 2"
            while wsconn.readyState == Open:
                let (op, seqbyte) = await wsconn.receivePacket()
                if op != Binary:
                    resp Http400, "invalid sent format"
                    wsconn.close()
                    return
                var cnt = 0
                if seqbyte.len < 4096:
                    await f.write seqbyte.join
                    continue
                
                while cnt < (seqbyte.len-4096):
                    let datastr = seqbyte[cnt .. cnt+4095].join
                    cnt.inc 4096
                    await f.write(datastr)
                
                wsconn.close()
            f.close()
        except:
            echo "websocket close: ", getCurrentExceptionMsg()
        redirect "success/" & @"name"

    get "/success/@name":
        var name: string = @"name"
        # This matches "/hello/fred" and "/hello/bob".
        # In the route ``@"name"`` will be either "fred" or "bob".
        # This can of course match any value which does not contain '/'.
        echo name
        resp success_page(name)

proc main() =
    let port = parseInt("3000").Port
    let staticDir = joinPath(getCurrentDir(), "/public")
    let settings = newSettings(port=port, staticDir=staticDir)
    var jester = initJester(myrouter, settings=settings)
    jester.serve()
    
when isMainModule:
    main()
