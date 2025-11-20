function charm
    if test (count $argv) -eq 0
        open -na "PyCharm.app" --args .
    else
        open -na "PyCharm.app" --args $argv[1]
    end
end
