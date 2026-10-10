function qr --description "Generate a QR code from a URL/string and copy the PNG to the clipboard"
    argparse 'o/output=' 'n/no-copy' 'k/keep' 'h/help' -- $argv
    or return

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "Usage: qr [options] <text-or-url>"
        echo ""
        echo "Options:"
        echo "  -o, --output PATH   Save PNG to PATH (default: temp file)"
        echo "  -n, --no-copy       Don't copy to clipboard"
        echo "  -k, --keep          Print the file path on completion"
        echo "  -h, --help          Show this help"
        return 0
    end

    set -l content $argv[1]
    set -l out_path

    if set -q _flag_output
        set out_path (path resolve $_flag_output)
    else
        set out_path (mktemp -t qr).png
    end

    set -l out_dir (path dirname $out_path)
    set -l out_name (path basename $out_path)

    uvx --from amzqr amzqr $content -n $out_name -d $out_dir >/dev/null
    or begin
        echo "qr: amzqr failed" >&2
        return 1
    end

    if not set -q _flag_no_copy
        osascript -e "set the clipboard to (read (POSIX file \"$out_path\") as «class PNGf»)"
        or begin
            echo "qr: clipboard copy failed" >&2
            return 1
        end
        echo "QR code copied to clipboard"
    end

    if set -q _flag_keep; or set -q _flag_output
        echo $out_path
    end
end
