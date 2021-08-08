package internal

import (
	"time"
	"sync"
	"fmt"
	"context"
	"io/ioutil"
	"net/http"
	"encoding/json"
)

const nodeTTL = time.Hour

type Node struct {
	Type 		string		`json:"type"`
	Name		string		`json:"name"`
	Secret		string		`json:"secret"`
	LoadedAt 	time.Time
}

func (node *Node) IsExpired() bool {
	return node.LoadedAt.Add(nodeTTL).Before(time.Now())
}

func (node *Node) Valid() bool {
	return len(node.Type) > 0 && len(node.Name) > 0 && len(node.Secret) > 0
}

var (
	nodes map[int64]Node
	mx sync.RWMutex
	httpClient = http.Client{
		Timeout: time.Duration(1 * time.Second),
	}
)

func init() {
	nodes = make(map[int64]Node)
}

func GetNode(id int64) *Node {
	mx.RLock()
	defer mx.RUnlock()

	node, ok := nodes[id]

	if ok && !node.IsExpired() {
		return &node
	} else {
		return nil
	}
}

func LoadNode(c context.Context, id int64) (*Node, error) {
	mx.Lock()
	defer mx.Unlock()

	node, ok := nodes[id]

	if ok && !node.IsExpired()  {
		return &node, nil
	}

	req, err := http.NewRequest("GET", fmt.Sprintf("%s/api/v1/admin/nodes/%d", config.ApiHost, id), nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(c)

	var resp *http.Response
	resp, err = httpClient.Do(req)

	if err != nil {
		return nil, err
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("Api response is %s", http.StatusText(resp.StatusCode))
	}

	var content []byte
	defer resp.Body.Close()

	content, err = ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	node = Node{}
	err = json.Unmarshal(content, &node)

	if err != nil {
		return nil, err
	}

	if !node.Valid() {
		return nil, fmt.Errorf("Node is not valid: %d", id)
	}

	node.LoadedAt = time.Now()
	nodes[id] = node

	return &node, nil
}
