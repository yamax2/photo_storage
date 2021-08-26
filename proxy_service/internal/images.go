package internal

import (
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/h2non/bimg"
)

func DownloadAndResize(imageURL string, node *Node, size int) ([]byte, error) {
	req, err := http.NewRequest("GET", imageURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", fmt.Sprintf("OAuth %s", node.Secret))
	resp, err := httpClient.Do(req)

	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	buf, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	options := bimg.Options{
		Width: size,
		Type:  bimg.WEBP,
	}

	if img, err := bimg.NewImage(buf).Process(options); err != nil {
		return nil, err
	} else {
		return img, nil
	}
}
