package main

import (
    "fmt"
    "net/http"
    "runtime"
)

func getArchHandler(w http.ResponseWriter, r *http.Request) {
    os := runtime.GOOS
    arch := runtime.GOARCH
    fmt.Println("responding to client request")
    fmt.Fprintf(w, "OS: %s\nArch: %s", os, arch)
}

func main() {
    http.HandleFunc("/go/getarch", getArchHandler)
    fmt.Println("starting Go server on port 8080")
    http.ListenAndServe(":8080", nil)
}