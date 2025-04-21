podman build --no-cache --rm -f Containerfile -t jetzig:demo .
podman run --interactive --tty -p 8080:8080 jetzig:demo
echo "browse http://localhost:8080/?name=test"
