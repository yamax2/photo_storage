package internal

import (
	"time"
)

const nodeTTL = time.Hour

type Node struct {
	Type 		string
	Name		string
	Secret		string
	LoadedAt 	time.Time
}

var nodes map[int64]Node

func init() {
	nodes = make(map[int64]Node)
}

func GetNode(id int64) *Node {
	value, ok := nodes[id]

	if ok && (value.LoadedAt.Add(nodeTTL).After(time.Now())) {
		return &value
	} else {
		return nil
	}
}
