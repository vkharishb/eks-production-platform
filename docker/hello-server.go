package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
)

func main() {
	text := flag.String("text", "Hello from EKS", "response body")
	listen := flag.String("listen", ":5678", "listen address")
	flag.Parse()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprintln(w, *text)
	})

	log.Printf("listening on %s", *listen)
	log.Fatal(http.ListenAndServe(*listen, nil))
}
