package internal

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestGetNode(t *testing.T) {
	t.Run("returns nil for non-existent node", func(t *testing.T) {
		assert.Nil(t, GetNode(1))
	})

	t.Run("returns nil for expired", func(t *testing.T) {
		nodes[1] = Node{
			Type: "yandex",
			Name: "test",
			Secret: "secret",
			LoadedAt: time.Now().Add(-2 * time.Hour),
		}

		assert.Nil(t, GetNode(1))
	})

	t.Run("returns value when not expired", func(t *testing.T) {
		nodes[1] = Node{
			Type: "yandex",
			Name: "test",
			Secret: "secret",
			LoadedAt: time.Now().Add(-59 * time.Minute),
		}

		assert.Equal(t, GetNode(1).Name, "test")
	})

	t.Cleanup(func() {
		nodes = make(map[int64]Node)
	})
}
