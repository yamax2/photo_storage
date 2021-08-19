package internal

import (
	"errors"
	"time"
	"sync"
	"fmt"
	"context"
	"net/http"
	"encoding/json"
	"encoding/base64"
	s "strings"

	"crypto/aes"
	"crypto/cipher"
	"crypto/md5"
)

const nodeTTL = 3 * time.Hour

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

func (node *Node) decodeSecret() error {
	decoded, err := base64.StdEncoding.DecodeString(node.Secret)

	if err != nil {
		return err
	}

	var block cipher.Block
	block, err = aes.NewCipher([]byte(config.secretSHA256))

	if err != nil {
		return err
	}

	if len(decoded)%aes.BlockSize != 0 {
		return errors.New("encoded secret is not a multiple of the block size")
	}

	iv := md5.Sum([]byte(node.Name))
	mode := cipher.NewCBCDecrypter(block, []byte(string(iv[:])))
	mode.CryptBlocks(decoded, decoded)

	node.Secret = s.Trim(string(decoded), "\x04\t\x00\r\n")

	return nil
}

var (
	nodes map[int64]Node
	mx sync.RWMutex
	httpClient = http.Client{
		Timeout: time.Duration(30 * time.Second),
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

	node = Node{}
	defer resp.Body.Close()

	if err := json.NewDecoder(resp.Body).Decode(&node); err != nil {
		return nil, err
	}

	if !node.Valid() {
		return nil, fmt.Errorf("Node is not valid: %d", id)
	}

	node.LoadedAt = time.Now()
	err = node.decodeSecret()

	if err != nil {
		return nil, err
	}

	nodes[id] = node

	return &node, nil
}
