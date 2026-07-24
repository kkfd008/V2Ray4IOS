// Package xraywrapper provides gomobile-bindable wrappers for Xray-core.
// Compile with: gomobile bind -target=ios -o XrayCore.xcframework .
package xraywrapper

import (
	"os"
	"path/filepath"
	"sync/atomic"

	"github.com/xtls/xray-core/core"
	_ "github.com/xtls/xray-core/main/distro/all"
)

var (
	server    *core.Instance
	upload    int64
	download  int64
)

// StartXray starts Xray-core with the given JSON config.
// configJSON: full V2Ray JSON configuration string.
// assetDir: directory containing geoip.dat and geosite.dat.
// Returns an empty string on success, or an error message on failure.
func StartXray(configJSON string, assetDir string) string {
	if server != nil {
		return "Xray is already running"
	}

	config, err := core.LoadConfig("stdin:", []byte(configJSON))
	if err != nil {
		return "Failed to load config: " + err.Error()
	}

	// Set asset directory
	if assetDir != "" {
		os.Setenv("xray.location.asset", assetDir)
	}

	server, err = core.New(config)
	if err != nil {
		return "Failed to create server: " + err.Error()
	}

	if err = server.Start(); err != nil {
		server = nil
		return "Failed to start server: " + err.Error()
	}

	return ""
}

// StopXray stops the running Xray-core instance.
func StopXray() {
	if server != nil {
		server.Close()
		server = nil
	}
}

// GetTrafficStats returns the accumulated upload and download bytes.
func GetTrafficStats() (up int64, down int64) {
	return atomic.LoadInt64(&upload), atomic.LoadInt64(&download)
}

// SetTrafficStats atomically sets the traffic counters.
func SetTrafficStats(up int64, down int64) {
	atomic.StoreInt64(&upload, up)
	atomic.StoreInt64(&download, down)
}

// Version returns the Xray-core version string.
func Version() string {
	return core.Version()
}

// GetAssetPath returns the asset directory path for the given base directory.
func GetAssetPath(baseDir string) string {
	return filepath.Join(baseDir, "assets")
}