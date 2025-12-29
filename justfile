@_default:
	just --list

caddy:
	caddy file-server --listen :8000

